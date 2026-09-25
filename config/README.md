# Configuration and reviewed decisions

Configuration files make source interpretation and publication choices explicit. They are tracked in Git; change them here, then rebuild affected data and exports. The [dataset guide](../docs/dataset.md) explains the processing decisions.

- [`ring_events/`](ring_events/README.md): source specifications, corrections, taxonomy, measurements, and moult rules.
- [`daily_covariates/`](daily_covariates/README.md): source-linked historical operations evidence.
- [`analysis/`](analysis/README.md): a capture-group rule shared by curation and downstream analyses.
- [`website/`](website/README.md): taxonomy mapping for website exports.
- [`publication/`](publication/README.md): common Zenodo, GBIF, citation, and repository metadata.
