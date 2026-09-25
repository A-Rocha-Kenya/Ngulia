# Curated data

This is the canonical local output of the dataset workflow:

| File | One row represents |
| --- | --- |
| `ring_events.csv` | One cleaned capture event for an individually marked bird. |
| `daily_counts.csv` | One species with a positive count on one date. |
| `daily_coverage.csv` | One calendar date in a ringing-season window, with coverage and covariate evidence. |
| `recoveries.csv` | One distinct recovery or control movement involving Ngulia. |

Read the [data dictionary and limitations](../../docs/dataset.md) before analysis. These CSVs are excluded from Git; the reviewed publication set is assembled under [`exports/zenodo/`](../../exports/README.md). Record a fixed dataset version or file checksums in downstream analyses.
