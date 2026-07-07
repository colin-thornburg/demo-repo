--------------------------------------------------------------------------------
-- Package : ETL_CUSTOMER
-- Procedure: LOAD_DIM_CUSTOMER
-- Purpose  : Builds the customer dimension (SCD Type 2) from the OLTP customer
--            and address tables. Handles new customers, tracks history on
--            attribute changes, and flags churned accounts.
-- Platform : Oracle 19c
-- Schedule : Nightly via DBMS_SCHEDULER job ETL_NIGHTLY_CUSTOMER
--
-- NOTE (legacy): This is procedural ETL. Staging is truncated and reloaded,
--                history is maintained via MERGE, and a cursor loop applies
--                per-row business rules that were never expressible in set SQL
--                (per the original author, ~2014).
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY etl_customer AS

  PROCEDURE load_dim_customer (p_run_date IN DATE DEFAULT SYSDATE) AS

    v_rows_ins   PLS_INTEGER := 0;
    v_rows_upd   PLS_INTEGER := 0;
    v_batch_id   NUMBER;
    v_err_msg    VARCHAR2(4000);

    -- Cursor over source customers joined to their primary address
    CURSOR c_src IS
      SELECT c.customer_id,
             c.first_name,
             c.last_name,
             c.email,
             c.phone,
             c.account_status,
             c.credit_limit,
             a.address_line1,
             a.city,
             a.state_province,
             a.postal_code,
             a.country_code,
             c.last_modified_ts
        FROM oltp.customers   c
        LEFT JOIN oltp.addresses a
          ON a.customer_id = c.customer_id
         AND a.address_type = 'PRIMARY';

  BEGIN

    -- 1) Grab a batch id from the control sequence
    SELECT etl_batch_seq.NEXTVAL INTO v_batch_id FROM dual;

    INSERT INTO etl_control.batch_log (batch_id, proc_name, start_ts, status)
    VALUES (v_batch_id, 'LOAD_DIM_CUSTOMER', SYSTIMESTAMP, 'RUNNING');
    COMMIT;

    -- 2) Rebuild staging from scratch (full snapshot each night)
    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg.stg_customer';

    INSERT INTO stg.stg_customer (
      customer_id, first_name, last_name, email, phone,
      account_status, credit_limit, address_line1, city,
      state_province, postal_code, country_code, src_modified_ts
    )
    SELECT customer_id, first_name, last_name,
           LOWER(TRIM(email))            AS email,
           REGEXP_REPLACE(phone,'[^0-9]','') AS phone,
           account_status,
           NVL(credit_limit, 0)          AS credit_limit,
           address_line1, city, state_province, postal_code,
           NVL(country_code,'US')        AS country_code,
           last_modified_ts
      FROM oltp.customers c
      LEFT JOIN oltp.addresses a
        ON a.customer_id = c.customer_id
       AND a.address_type = 'PRIMARY';

    -- 3) Close out changed records in the dimension (SCD2 expire step)
    UPDATE dw.dim_customer d
       SET d.effective_end_dt = p_run_date - 1,
           d.is_current       = 'N'
     WHERE d.is_current = 'Y'
       AND EXISTS (
             SELECT 1
               FROM stg.stg_customer s
              WHERE s.customer_id = d.customer_id
                AND (   NVL(s.email,'~')          <> NVL(d.email,'~')
                     OR NVL(s.phone,'~')          <> NVL(d.phone,'~')
                     OR NVL(s.account_status,'~') <> NVL(d.account_status,'~')
                     OR NVL(s.credit_limit,-1)    <> NVL(d.credit_limit,-1)
                     OR NVL(s.city,'~')           <> NVL(d.city,'~')
                     OR NVL(s.postal_code,'~')    <> NVL(d.postal_code,'~')
                    )
           );
    v_rows_upd := SQL%ROWCOUNT;

    -- 4) Insert new + newly-changed versions as current rows
    INSERT INTO dw.dim_customer (
      customer_sk, customer_id, first_name, last_name, email, phone,
      account_status, credit_limit, address_line1, city, state_province,
      postal_code, country_code, effective_start_dt, effective_end_dt,
      is_current, batch_id
    )
    SELECT dim_customer_seq.NEXTVAL,
           s.customer_id, s.first_name, s.last_name, s.email, s.phone,
           s.account_status, s.credit_limit, s.address_line1, s.city,
           s.state_province, s.postal_code, s.country_code,
           p_run_date, DATE '9999-12-31', 'Y', v_batch_id
      FROM stg.stg_customer s
      LEFT JOIN dw.dim_customer d
        ON d.customer_id = s.customer_id
       AND d.is_current  = 'Y'
     WHERE d.customer_id IS NULL   -- brand new customer
        OR (  NVL(s.email,'~')          <> NVL(d.email,'~')
           OR NVL(s.phone,'~')          <> NVL(d.phone,'~')
           OR NVL(s.account_status,'~') <> NVL(d.account_status,'~')
           OR NVL(s.credit_limit,-1)    <> NVL(d.credit_limit,-1)
           OR NVL(s.city,'~')           <> NVL(d.city,'~')
           OR NVL(s.postal_code,'~')    <> NVL(d.postal_code,'~')
           );
    v_rows_ins := SQL%ROWCOUNT;

    -- 5) Per-row business rule: flag long-dormant accounts as CHURNED.
    --    Kept as a cursor loop because the original tiering logic branched
    --    on multiple thresholds and wrote to an audit table row-by-row.
    FOR r IN c_src LOOP
      IF r.account_status = 'ACTIVE'
         AND r.last_modified_ts < ADD_MONTHS(p_run_date, -18) THEN

        UPDATE dw.dim_customer
           SET account_status = 'CHURNED'
         WHERE customer_id = r.customer_id
           AND is_current  = 'Y';

        INSERT INTO dw.customer_status_audit
          (customer_id, old_status, new_status, changed_ts, batch_id)
        VALUES
          (r.customer_id, 'ACTIVE', 'CHURNED', SYSTIMESTAMP, v_batch_id);

      END IF;
    END LOOP;

    -- 6) Finalize control row
    UPDATE etl_control.batch_log
       SET end_ts      = SYSTIMESTAMP,
           status      = 'SUCCESS',
           rows_inserted = v_rows_ins,
           rows_updated  = v_rows_upd
     WHERE batch_id = v_batch_id;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      v_err_msg := SUBSTR(SQLERRM, 1, 4000);
      ROLLBACK;
      UPDATE etl_control.batch_log
         SET end_ts    = SYSTIMESTAMP,
             status    = 'FAILED',
             error_msg = v_err_msg
       WHERE batch_id = v_batch_id;
      COMMIT;
      RAISE;

  END load_dim_customer;

END etl_customer;
/