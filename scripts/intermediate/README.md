# Intermediate builders

`01_build_daily_context.R` combines source-specific daily observations, moon variables, operations evidence, and ERA5. `02_build_mist_model.R` estimates the three-state mist distribution used by the curated daily table. Run both before `scripts/curated/05_build_daily_coverage.R`.

`03_extract_geolocator_paths.R` stages paths used by website exports and exploratory movement figures. Outputs are regenerable under [`data/03_intermediate/`](../../data/03_intermediate/README.md). See [daily covariate evidence](../../docs/daily_covariates.md) for source priorities and uncertainty.
