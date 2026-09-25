# Dataset publication

The public [Ngulia website](https://a-rocha-kenya.github.io/ngulia-website/) is the project entry point and already hosts the interactive science dashboard. This repository owns the curated dataset, its descriptive exploration, and the data exports. The separate [forecast](https://a-rocha-kenya.github.io/ngulia-forcast/) serves its operational dashboard; [ngulia-analysis](https://github.com/A-Rocha-Kenya/ngulia-analysis) holds question-specific research.

## Current status

- **Zenodo:** The six-file upload and form worksheet can be generated, but no resolving concept DOI is recorded yet. The former `10.5281/zenodo.21395879` value did not resolve when checked on 2026-09-25, so it has been removed from publication metadata.
- **GBIF:** The Darwin Core Archive can be generated locally. No Ngulia dataset was returned for the configured A Rocha Kenya publisher in the GBIF API check on 2026-09-25. GBIF registration and ingestion remain pending.

## Before creating records

1. Rebuild the four curated tables from the current scripts and review the QA outputs, particularly the ring-event corrections, coverage evidence, and recoveries.
2. Run `scripts/exploration/dataset_overview/` and check the descriptive summaries and figures.
3. Run `Rscript scripts/exports/00_build_citation.R`, `Rscript scripts/exports/02_build_zenodo_package.R`, and `Rscript scripts/exports/03_build_gbif_export.R`.
4. Review `exports/zenodo/zenodo_form.md`, the six listed upload files, and `exports/gbif/ngulia_gbif_dwca.zip`. Confirm licenses, attribution, geographic coordinates, record counts, and interpretation limits.

## Publication order

1. Create a Zenodo dataset record from the six listed files and the worksheet. Record the **version DOI**, concept DOI, version number, publication date, Git commit, and file checksums. Do not use the concept DOI as a fixed input version for analyses.
2. Add the verified concept DOI to `config/publication/dataset_metadata.yml`, regenerate the GBIF archive, and register or update the dataset under the configured A Rocha Kenya GBIF publisher. The GBIF resource contains the ringing-event subset; Zenodo contains the broader curated research dataset.
3. After both records resolve, add their links and a short dataset guide to the existing website dashboard and data page. Keep scientific interpretation and the main interactive dashboard there. This repository can show reproducible static dataset figures in its README or documentation without creating a second public portal.

The current local export files are preparation artifacts. Neither an export file nor a DOI written in metadata proves that a public record is live.
