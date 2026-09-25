# Configuration and reviewed decisions

These tracked files make source interpretation and publication choices explicit:

| Folder | Role |
| --- | --- |
| `ring_events/` | Workbook specifications, corrections, ring history, lookups, measurements, and moult rules. |
| `daily_counts/` | Targeted capture-group classification used to distinguish the catch processes in daily coverage. |
| `daily_covariates/` | Source-linked operations history and reviewed daily evidence. |
| `website/` | Taxonomy mapping for website exports. |
| `publication/` | Shared citation, Zenodo, and GBIF metadata. |

Change a rule here, then rebuild affected tables and exports with [`scripts/`](../scripts/README.md). Details are in the [dataset guide](../docs/dataset.md), [daily covariate evidence](../docs/daily_covariates.md), and [publication guide](../docs/publication.md). Question-specific choices belong in `ngulia-analysis`.
