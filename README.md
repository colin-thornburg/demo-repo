Welcome to your new dbt project!

## Project playbooks

This repo includes a project-specific skill/playbook for future modeling work:

- `.agents/skills/remanufacturing-data-vault-playbook/SKILL.md`

Use it when:
- `automate_dv` shows editor or package-version issues under Fusion
- new source data lands first as seed files
- remanufacturing process data needs to be modeled with Data Vault principles before being exposed as marts

Recommended workflow for new remanufacturing data:
1. land the source extracts in `seeds/`
2. inspect headers and sample rows
3. identify business keys, relationships, and event grain
4. build `stg_<subject>` and `stg_vault_<subject>` models
5. add hubs, links, and satellites
6. expose marts only where consumers need them

If `automate_dv` errors appear in the editor, validate with dbt runtime first:
- `dbt deps`
- `dbt compile --select <model> --no-partial-parse`
- `dbt build --select +<model>+`

### Using the starter project

Try running the following commands:
- dbt run
- dbt test

### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [dbt community](https://getdbt.com/community) to learn from other analytics engineers
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
