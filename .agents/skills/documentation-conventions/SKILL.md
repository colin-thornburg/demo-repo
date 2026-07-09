---
name: documentation-conventions
description: Apply our aesthetics-business documentation standards when writing or improving dbt model and column descriptions. Use whenever the user asks to document models, fill in blank descriptions, or improve existing YAML descriptions in this project.
---

# Documentation conventions

Use this skill when generating or improving `description` fields in dbt YAML.

## Voice and format
- Write plain, factual prose. One to two sentences per column.
- Start column descriptions with a noun phrase, not "This column...".
- Never restate the column name as the description (e.g. do NOT write
  "The ID of the provider" for `provider_id`). Explain what it means and how it's used.
- For any code/enum column, list the possible values and what each means.
- For any flag or filter column, explain what downstream logic depends on it.

## Investigate before documenting
If a column's meaning is not obvious from its name and SQL, query the warehouse
to inspect distinct values, distributions, and relationships before writing the
description. Base the description on what the data actually shows.

## Business context
- **Customers are provider practices**, not patients. A `provider` is an account
  such as a dermatology practice, plastic surgery group, or med spa that orders
  our products. We never store patient-level data in these models.
- **product_family** identifies the brand line ordered: BOTOX, JUVEDERM, KYBELLA,
  SKINVIVE, and COOLSCULPTING.
- **provider_specialty** values: `derm` (dermatology), `plastics` (plastic surgery),
  `med_spa`, and `facial_plastics`.
- **billing_system**: practices are billed through either `alle_direct` (direct
  Allergan Aesthetics billing, tied to the Alle loyalty ecosystem) or `gpo`
  (group purchasing organization). A practice can hold concurrent accounts in
  both, producing duplicate rows that share one `provider_id`. The canonical
  record is the `alle_direct` row; the `gpo` duplicate is flagged and filtered
  out in staging.
- **order_status** codes: S = shipped, R = returned, B = backordered, C = cancelled.
- **Units and revenue rule**: `units_dispensed` counts shipped units minus free
  samples (`units_sampled`). Only orders with status S (shipped) count toward
  recognized product revenue; returned, backordered, and cancelled orders are excluded.
- **cold_chain_flag** marks temperature-controlled shipments (required for
  BOTOX and JUVEDERM); it drives fulfillment and compliance logic downstream.
