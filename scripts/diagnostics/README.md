# Diagnostics and QA

These scripts assess source dates, daily-count reconciliation, daily covariates and effort, mist-model fit, and ring-event measurements. They write review tables or figures under [`outputs/qa/`](../../outputs/README.md) and do not change the curated CSVs.

Run the relevant check after changing curation rules or rebuilding data. Machine-readable source audits remain under `data/03_intermediate/`; interpretation limits and validation notes are in [the dataset guide](../../docs/dataset.md).
