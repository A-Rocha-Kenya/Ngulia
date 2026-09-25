# Intermediate data

Regenerable working tables and machine-readable curation audits live here. The `ring_events/` and `daily_counts/` folders retain source-specific staging and audits; `weather/`, `daily_context/`, and `mist_model/` feed the curated daily coverage table. `geolocator_paths/` supports website and exploratory exports.

Rebuild these files with [`scripts/curated/`](../../scripts/curated/README.md) and [`scripts/intermediate/`](../../scripts/intermediate/README.md). They are local, excluded from Git, and are not the public dataset. The published table definitions are in [the dataset guide](../../docs/dataset.md).
