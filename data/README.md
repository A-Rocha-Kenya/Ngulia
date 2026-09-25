# Data

The local data pipeline runs from source material to four curated CSV tables:

| Folder | Role |
| --- | --- |
| `01_raw/` | Original workbooks, count sources, weather archives, and external inputs; do not edit in place. |
| `02_reference/` | Taxonomy, publications, reports, ranges, and supporting material. |
| `03_intermediate/` | Regenerable staging tables and machine-readable curation audits. |
| `04_curated/` | Canonical `ring_events.csv`, `daily_counts.csv`, `daily_coverage.csv`, and `recoveries.csv`. |

The data files are local and excluded from Git. Field definitions, processing decisions, and limitations are in the [dataset guide](../docs/dataset.md); publication status is in [the publication guide](../docs/publication.md).
