# Remanufacturing Data Vault Playbook

Use this skill when working in this project on new source data that lands first as dbt seeds, especially Caterpillar remanufacturing process data, or when using the `automate_dv` package under dbt Fusion.

## What this skill is for

This project is evolving from legacy procedural ETL into dbt models on Snowflake with a practical Data Vault pattern:
- business-facing marts stay easy to consume
- integration logic is modeled with hubs, links, and satellites
- early-stage source drops often arrive first as seed files

Use this skill to:
- prevent `automate_dv` package/version confusion in Fusion
- turn new seed-based source tables into a repeatable Vault slice
- connect new remanufacturing entities into the existing customer/sales-style pipeline pattern

## Non-negotiables for this repo

- Always inspect `dbt_project.yml` before creating files.
- Always use modern dbt syntax in YAML: `data_tests:`.
- Always use `--select`, never legacy `--models` or `-m`.
- Read the seed headers before modeling. Do not infer column names.
- When validating new SQL models, use `dbt build --select +<model>+`.
- Do not edit generated or vendored files in `dbt_packages/`, `target/`, or `logs/`.

## Package + version guardrails for `automate_dv`

### Known issue pattern

In this repo, `automate_dv` may show editor/parser errors like:
- `unknown function`
- `No macro named 'stage' found within namespace: 'automate_dv'`
- dispatch-related Jinja errors in the IDE

This can happen even when dbt runtime is fine.

### Why it happens

`automate_dv` may lag Fusion support. The package can still compile and build successfully through dbt while Studio/editor static analysis shows false positives.

### Required verification steps

When an `automate_dv` error appears, do these before changing code:

1. Confirm the package is installed in `packages.yml`.
2. Confirm the installed package name in `dbt_packages/automate_dv/dbt_project.yml` is `automate_dv`.
3. Confirm the model is calling the package with the same namespace, for example:
   - `{{ automate_dv.stage(...) }}`
   - `{{ automate_dv.hub(...) }}`
   - `{{ automate_dv.link(...) }}`
   - `{{ automate_dv.sat(...) }}`
4. Run a fresh compile without partial parsing:
   - `dbt compile --select <model_name> --no-partial-parse`
5. If compile succeeds, treat the IDE error as a false positive.

### Decision rule

If `dbt compile --no-partial-parse` or `dbt build` succeeds, do not rewrite the model just to satisfy the editor.

Only remove `automate_dv` usage when one of these is true:
- runtime compile fails in dbt, not just in the editor
- package macros are incompatible with the installed Fusion runtime
- the package blocks new modeling work or team adoption

### Preferred response to future package errors

Use this sequence:
1. `dbt deps`
2. `dbt parse --no-partial-parse` or `dbt compile --select <model> --no-partial-parse`
3. build the affected node with ancestors
4. only then decide whether code changes are needed

Do not assume a namespace typo if runtime compile succeeds.

## How to model new seed-based remanufacturing data

New operational tables will often land as seeds first. Treat them like raw landed source extracts and model from them cleanly.

### Recommended layer pattern in this repo

For each new subject area:
1. **Seed(s)** in `seeds/`
2. **Business staging model(s)** in `models/staging/`
3. **Vault hashed staging model** in `models/staging/`
4. **Hubs / links / satellites** in `models/marts/` until a dedicated `models/vault/` path exists
5. **Business-facing mart/fact/dimension** on top when needed

### Start from business keys and grain

For every new seed, identify:
- the business key for each core entity
- the transaction/event grain
- whether the table is a descriptive entity, relationship table, or event/measurement table
- the load timestamp / effective timestamp / source freshness timestamp

### Natural Data Vault mapping rules

Use these defaults unless the data clearly says otherwise:

#### Hubs
Create a hub for stable business keys such as:
- core / engine / component serial number
- work order number
- reman order number
- claim number
- dealer id
- supplier id
- customer id
- plant / facility id
- part number when treated as a business entity

Hub rule:
- one hub per stable business concept
- hub payload should stay minimal
- the hub exists to anchor business identity across processes

#### Links
Create links for business relationships such as:
- work order to component
- component to part
- reman order to customer
- work order to facility
- return shipment to received core
- inspection to work order
- teardown event to component

Link rule:
- links capture relationships at the natural operational grain
- if the relationship itself has changing descriptive context, keep that in a satellite off the link

#### Satellites
Create satellites for descriptive or changing attributes such as:
- inspection outcomes
- condition codes
- reason codes
- pricing / cost snapshots
- status changes
- location / operational attributes
- quality measurements
- cycle time metrics
- work order details

Satellite rule:
- group payload by rate of change and business meaning
- avoid one giant catch-all satellite unless the source is tiny and stable

### Practical remanufacturing patterns

Use these common patterns as defaults:

#### 1. Core lifecycle data
If seeds describe a returned core through inspection, teardown, rebuild, and shipment:
- Hub: core/component
- Hubs: work_order, facility, possibly dealer/customer
- Links: core-to-work-order, core-to-facility, core-to-customer/dealer
- Satellites: inspection, teardown, rebuild status, disposition, quality metrics

#### 2. Parts consumption / replacement data
If seeds describe components consumed or replaced during reman:
- Hub: part
- Link: work_order-to-part or component-to-part
- Satellite: quantity, unit cost, issue reason, replacement class, scrap/repair flag

#### 3. Event history / status streams
If seeds are event logs:
- preserve event grain in the business stage
- hash the business keys in Vault stage
- choose whether status belongs in a sat on the hub or a sat on the link based on whether the status describes the entity or the relationship/event

### Seed-first modeling workflow

For every new seed subject area, follow this sequence:

1. Read the seed headers and sample rows.
2. Decide the core business entities, relationships, and event grain.
3. Create a business stage that:
   - standardizes types
   - normalizes codes/text
   - derives load/effective timestamps
   - removes obvious source quirks
4. Create a Vault hashed stage with:
   - hub hash keys
   - link hash keys
   - hashdiff columns for satellites
   - `src_ldts`
   - `src_source`
5. Add hubs, links, and satellites.
6. Add business-facing facts or dimensions only where consumers need them.
7. Add tests for hub uniqueness/not-null, link not-null on foreign hashes, and sat not-null on PK/hashdiff/load timestamp.
8. Validate with `dbt build --select +<target_model>+`.

## Naming guidance

Use readable names that match the current repo style.

### Staging
- `stg_<subject>.sql` for business staging
- `stg_vault_<subject>.sql` for hashed Vault staging

### Hubs
- `hub_<entity>.sql`
- hash key columns like `hk_<entity>_h`

### Links
- `link_<relationship>.sql`
- link hash key columns like `hk_<relationship>_l`

### Satellites
- `sat_<entity_or_relationship>_<theme>.sql`
- hashdiff columns like `hd_<entity_or_relationship>_<theme>_s`

### Business marts
- `fact_<subject>.sql`
- `dim_<subject>.sql`
- `fct_` is fine only if the repo already standardizes on it

## Tests to add by default

### Hubs
- hash key: `not_null`, `unique`

### Links
- link hash key: `not_null`, `unique`
- each foreign hub hash key: `not_null`
- add relationships tests when the upstream hub is present and materialized

### Satellites
- parent hash key: `not_null`
- hashdiff: `not_null`
- `src_ldts`: `not_null`

### Business marts
Add only the high-value tests first:
- grain columns `not_null`
- unique grain test when appropriate
- important measures `not_null` where business logic guarantees them
- relationships to dimensions where consumers depend on conformance

## When to avoid over-modeling

Do not force every seed into a sprawling Vault if the data is tiny, temporary, or clearly one-off.

Use a thinner pattern when:
- the seed is a one-table lookup/reference dataset
- the data has no real historical or relational behavior
- the business value is a direct mart and a Vault layer adds only ceremony

Still prefer clean staging and tests.

## Suggested future workflow for this repo

When new remanufacturing seeds arrive:
- inspect all new seed files together
- identify shared hubs across them before writing any SQL
- build one coherent Vault slice instead of one-off models per file
- plug that slice into downstream marts incrementally

## Example decision prompts to apply

Before writing models, answer:
- What is the business key?
- What is the natural transaction grain?
- Is this row describing an entity, a relationship, or an event?
- Which attributes change together?
- Does a business-facing mart actually need this yet?

If the answers are unclear, read more seed rows first instead of guessing.
