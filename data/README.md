# Data

The data pipeline runs from source material to four curated CSV tables. Detailed field definitions, source choices, and interpretation limits are in [the dataset guide](../docs/dataset.md).

| Folder | Role |
| --- | --- |
| [`01_raw/`](01_raw/README.md) | Original source files; do not edit in place. |
| [`02_reference/`](02_reference/README.md) | Taxonomy, publications, ranges, and other supporting material. |
| [`03_intermediate/`](03_intermediate/README.md) | Regenerable staging tables and curation audits. |
| [`04_curated/`](04_curated/README.md) | Canonical analysis-ready tables and source for publication exports. |

Data files are local and excluded from Git. See [publication status](../docs/publication.md) for the Zenodo and GBIF records.
