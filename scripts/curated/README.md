# Curated table builders

Run these scripts from the repository root in numeric order. They build ring events, stage DJP counts, consolidate daily counts, summarize ERA5 weather, and produce daily coverage. Run [`intermediate/01_build_daily_context.R`](../intermediate/README.md) and `02_build_mist_model.R` after weather and before `05_build_daily_coverage.R`.

`06_standardize_recovery_encounters.R` applies labels to the manually curated recovery table; the source consolidation is not regenerated here. Outputs are in [`data/04_curated/`](../../data/04_curated/README.md), with staging and audits in `data/03_intermediate/`. Full order and processing decisions are in [the dataset guide](../../docs/dataset.md).
