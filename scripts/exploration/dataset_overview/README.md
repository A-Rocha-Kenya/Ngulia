# Dataset overview

Run `00_summarize_datasets.R` for species, season, and day tables, then `01_plot_daily_rings_by_season.R` for the season matrix. Both read [`data/04_curated/`](../../../data/04_curated/README.md) and write to `outputs/exploration/dataset_overview/`.

The reviewed figure copied to `assets/generated/daily_rings_by_season.png` appears on the root README. Blank days in this figure are not automatically zero-catch days; use `daily_coverage.csv` to interpret coverage.
