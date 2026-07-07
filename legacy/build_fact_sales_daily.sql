--------------------------------------------------------------------------------
-- Package : ETL_SALES
-- Procedure: BUILD_FACT_SALES_DAILY
-- Purpose  : Builds the daily sales fact by aggregating order lines, applying
--            returns/refunds as offsets, joining currency rates, and upserting
--            into the reporting fact. Also refreshes a materialized rollup.
-- Platform : Oracle 19c
-- Schedule : Nightly, after LOAD_DIM_CUSTOMER completes.
--
-- NOTE (legacy): Uses a global temp table for the intermediate aggregate,
--                several sequential DML passes, a MERGE for the upsert, and
--                a DELETE-based reprocessing window for late-arriving data.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY etl_sales AS

  PROCEDURE build_fact_sales_daily (
    p_run_date      IN DATE     DEFAULT TRUNC(SYSDATE) - 1,
    p_reprocess_days IN PLS_INTEGER DEFAULT 3
  ) AS

    v_start_dt   DATE := p_run_date - p_reprocess_days;
    v_end_dt     DATE := p_run_date;
    v_batch_id   NUMBER;
    v_rows       PLS_INTEGER := 0;

  BEGIN

    SELECT etl_batch_seq.NEXTVAL INTO v_batch_id FROM dual;

    -- 1) Clear the reprocessing window so late-arriving orders don't double count
    DELETE FROM dw.fact_sales_daily
     WHERE sales_date BETWEEN v_start_dt AND v_end_dt;

    -- 2) Load a global temp table with base order-line aggregates
    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg.gtt_sales_agg';

    INSERT INTO stg.gtt_sales_agg (
      sales_date, customer_id, product_id, store_id,
      order_qty, gross_amount, line_count
    )
    SELECT TRUNC(o.order_ts)        AS sales_date,
           o.customer_id,
           ol.product_id,
           o.store_id,
           SUM(ol.quantity)         AS order_qty,
           SUM(ol.quantity * ol.unit_price) AS gross_amount,
           COUNT(*)                 AS line_count
      FROM oltp.orders       o
      JOIN oltp.order_lines  ol ON ol.order_id = o.order_id
     WHERE TRUNC(o.order_ts) BETWEEN v_start_dt AND v_end_dt
       AND o.order_status = 'COMPLETED'
     GROUP BY TRUNC(o.order_ts), o.customer_id, ol.product_id, o.store_id;

    -- 3) Apply returns as negative offsets against the same grain
    MERGE INTO stg.gtt_sales_agg t
    USING (
      SELECT TRUNC(r.return_ts)     AS sales_date,
             r.customer_id,
             rl.product_id,
             r.store_id,
             SUM(rl.quantity)               AS ret_qty,
             SUM(rl.quantity * rl.unit_price) AS ret_amount
        FROM oltp.returns      r
        JOIN oltp.return_lines rl ON rl.return_id = r.return_id
       WHERE TRUNC(r.return_ts) BETWEEN v_start_dt AND v_end_dt
       GROUP BY TRUNC(r.return_ts), r.customer_id, rl.product_id, r.store_id
    ) s
    ON (    t.sales_date = s.sales_date
        AND t.customer_id = s.customer_id
        AND t.product_id  = s.product_id
        AND t.store_id    = s.store_id)
    WHEN MATCHED THEN UPDATE
      SET t.order_qty    = t.order_qty    - s.ret_qty,
          t.gross_amount = t.gross_amount - s.ret_amount
    WHEN NOT MATCHED THEN INSERT
      (sales_date, customer_id, product_id, store_id,
       order_qty, gross_amount, line_count)
      VALUES
      (s.sales_date, s.customer_id, s.product_id, s.store_id,
       -s.ret_qty, -s.ret_amount, 0);

    -- 4) Convert to reporting currency using the daily rate table.
    --    Rows with no rate fall back to 1.0 (assumed USD-native).
    UPDATE stg.gtt_sales_agg g
       SET g.gross_amount = g.gross_amount *
             NVL( (SELECT fx.rate_to_usd
                     FROM ref.fx_daily_rates fx
                    WHERE fx.rate_date = g.sales_date
                      AND fx.currency_code = (
                            SELECT s.currency_code
                              FROM oltp.stores s
                             WHERE s.store_id = g.store_id))
                 , 1.0);

    -- 5) Derive customer_sk from the current dimension version, then upsert
    --    into the reporting fact.
    MERGE INTO dw.fact_sales_daily f
    USING (
      SELECT g.sales_date,
             d.customer_sk,
             g.product_id,
             g.store_id,
             g.order_qty,
             g.gross_amount,
             g.line_count
        FROM stg.gtt_sales_agg g
        LEFT JOIN dw.dim_customer d
          ON d.customer_id = g.customer_id
         AND d.is_current  = 'Y'
    ) src
    ON (    f.sales_date  = src.sales_date
        AND f.customer_sk = src.customer_sk
        AND f.product_id  = src.product_id
        AND f.store_id    = src.store_id)
    WHEN MATCHED THEN UPDATE
      SET f.order_qty    = src.order_qty,
          f.gross_amount = src.gross_amount,
          f.line_count   = src.line_count,
          f.batch_id     = v_batch_id
    WHEN NOT MATCHED THEN INSERT
      (sales_date, customer_sk, product_id, store_id,
       order_qty, gross_amount, line_count, batch_id)
      VALUES
      (src.sales_date, src.customer_sk, src.product_id, src.store_id,
       src.order_qty, src.gross_amount, src.line_count, v_batch_id);

    v_rows := SQL%ROWCOUNT;

    -- 6) Conditional refresh of the monthly rollup MV only when we touched
    --    the current month (avoids an expensive refresh on backfills).
    IF EXTRACT(MONTH FROM v_end_dt) = EXTRACT(MONTH FROM SYSDATE)
       AND EXTRACT(YEAR FROM v_end_dt) = EXTRACT(YEAR FROM SYSDATE) THEN
      DBMS_MVIEW.REFRESH('DW.MV_SALES_MONTHLY', 'C');
    END IF;

    INSERT INTO etl_control.batch_log
      (batch_id, proc_name, start_ts, end_ts, status, rows_upserted)
    VALUES
      (v_batch_id, 'BUILD_FACT_SALES_DAILY', SYSTIMESTAMP, SYSTIMESTAMP,
       'SUCCESS', v_rows);

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      INSERT INTO etl_control.batch_log
        (batch_id, proc_name, start_ts, end_ts, status, error_msg)
      VALUES
        (v_batch_id, 'BUILD_FACT_SALES_DAILY', SYSTIMESTAMP, SYSTIMESTAMP,
         'FAILED', SUBSTR(SQLERRM,1,4000));
      COMMIT;
      RAISE;

  END build_fact_sales_daily;

END etl_sales;
/