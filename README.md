# dbt Wizard documentation demo (dbt Studio UI, one-off)

A small, self-contained dbt project for demoing context-aware bulk documentation
with dbt Wizard in the **dbt Studio UI** — no CLI, nothing repeatable. Everything
runs off seeds, so there's no external source setup.

The demo shows a single manual run through three phases:

1. **Define what's missing** — find the columns with blank/weak descriptions.
2. **Deep scan to understand meaning** — Wizard queries the warehouse to work out
   what the ambiguous columns actually mean.
3. **Generate the documentation** — Wizard writes real descriptions and shows a
   diff you approve.

## What's inside
- **seeds/** — `raw_providers`, `raw_orders`, `raw_shipments` (CSV)
- **models/staging/** — `stg_providers`, `stg_orders`, `stg_shipments` + `_staging.yml`
- **models/marts/** — `fct_provider_orders` + `_marts.yml`
- **.agents/skills/documentation-conventions/** — the skill carrying the business context

All `description` fields in the YAML are intentionally **blank** — those are the
gaps the demo fills.

## The domain (fake data, Allergan-relevant columns)
Customers are **provider practices** (derm, plastics, med spa) ordering aesthetic
product lines — BOTOX, JUVEDERM, KYBELLA, SKINVIVE, COOLSCULPTING. Columns an
Allergan analytics team would recognize: `product_family`, `provider_specialty`,
`billing_system`, `units_dispensed`, `cold_chain_flag`.

## The two planted "puzzles" (your deep-scan moments)
These are columns whose meaning a generic agent can't guess — so Wizard has to
investigate, which is the whole point of phase 2.

1. **`is_duplicate_account`** — practices can hold concurrent `alle_direct` and
   `gpo` billing accounts under one `provider_id`, creating duplicate rows.
   Staging keeps the `alle_direct` record. A naive agent writes "flags a duplicate";
   a skill-informed agent explains *why* duplicates exist and which record survives.
2. **`order_status`** — opaque single-letter codes (S/R/B/C). Without context an
   agent guesses; with the data + skill it decodes them (S = shipped, etc.) and
   notes that only S counts toward recognized revenue.

## Demo flow (dbt Studio UI)

**Setup (once):** load this repo into a dbt platform project, connect a warehouse,
run `dbt seed` then `dbt build` so Wizard's metadata engine and profiling have data.

**Phase 1 — Define what's missing.** In the Wizard panel (Studio IDE or home tab),
prompt:

> Scan models/staging and models/marts and list every column whose description is
> blank or just restates the column name.

**Phase 2 + 3 — Deep scan, then generate.** The skill is already in `.agents/skills/`.
Start a **new chat** (skills load at session start), then prompt:

> Using the documentation-conventions skill, fill in all blank descriptions in
> stg_providers, stg_orders, and fct_provider_orders. For any column whose meaning
> isn't obvious — like is_duplicate_account or order_status — investigate the
> warehouse data first, then write the description. Show me the diff before saving.

Wizard reads the skill, runs read-only SQL to confirm the duplicate-account and
status-code logic, writes descriptions that explain the *why*, and presents a diff
for you to approve.

### Optional: show the contrast
To make the value obvious, run a **baseline** first with no skill (a fresh chat,
just "fill in the blank descriptions in stg_providers"). The two puzzle columns
come out generic. Then do the skill run above and compare — same model, better
descriptions, purely because of the context you supplied.

### Optional: mention subagents
For a larger scan you can ask Wizard to split the work across subagents (built-in
roles like `explorer`) — this works in the UI, no setup needed. It's optional here
since the project is small.
- Subagents in the dbt platform: https://docs.getdbt.com/docs/dbt-ai/wizard-platform-subagents

## Notes
- Skills are discovered at session start — after editing the skill, start a new chat.
- Because phase 2 queries live warehouse data, confirm data-handling/PII expectations
  before pointing Wizard at real Allergan data. (This demo uses only fake seed data.)
- Swap the business context in SKILL.md for the customer's real conventions to make
  the descriptions land even harder.
