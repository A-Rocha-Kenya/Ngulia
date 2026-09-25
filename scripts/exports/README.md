# Export builders

Run from the repository root after rebuilding and reviewing curated data:

1. `00_build_citation.R` updates the root README and `CITATION.cff` from publication metadata.
2. `01_build_website_exports.R` creates website-ready files under `exports/website/`.
3. `02_build_zenodo_package.R` creates six upload files, checksums, a README, and a form worksheet under `exports/zenodo/`.
4. `03_build_gbif_export.R` creates the Darwin Core Archive under `exports/gbif/`.

The generated output folders are ignored by Git. See [`exports/`](../../exports/README.md) for their contents and [publication status](../../docs/publication.md) before using them externally.
