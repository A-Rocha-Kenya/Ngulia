library(yaml)
library(stringr)
library(purrr)
library(glue)
library(cli)

source(here::here("scripts/helpers/publication_metadata.R"))

metadata <- read_publication_metadata()
author_table <- publication_author_table(metadata$authors)

readme <- glue(
  "# {metadata$dataset$title}\n\n",
  "{metadata$dataset$description}\n\n",
  "{metadata$repository$website_note}\n\n",
  "## Authors and contributor roles\n\n",
  "Roles describe contributions to this curated dataset and are a project-maintained attribution record.\n\n",
  "{author_table}\n\n",
  "## Project guide\n\n",
  "- [Dataset documentation](docs/dataset.md): files, data dictionary, processing, and run order.\n",
  "- [Publication status](docs/publication.md): Zenodo and GBIF preparation and record checks.\n",
  "- [Dataset exploration](scripts/exploration/dataset_overview/): descriptive tables and figures.\n",
  "- [Data limitations](docs/data_limitations.md): interpretation limits for catch, effort, and historical covariates.\n",
  "- [Daily covariate evidence](config/daily_covariates/README.md): operations-history structure and evidence rules.\n",
  "- [Field protocol planning](docs/planning/field_protocol.md): future measurements and standardisation.\n\n",
  "## Repository layout\n\n",
  "`data/01_raw/` holds source material; `data/02_reference/` holds reference material; ",
  "`data/03_intermediate/` holds regenerable staging products; and `data/04_curated/` holds analysis-ready datasets. ",
  "Scripts progress through `scripts/curated/`, `scripts/intermediate/`, `scripts/exploration/`, `scripts/diagnostics/`, and `scripts/exports/`. ",
  "Generated exploration and QA products are written under `outputs/`; delivery formats under `exports/`.\n\n",
  "Question-specific research is maintained in [ngulia-analysis](https://github.com/A-Rocha-Kenya/ngulia-analysis). ",
  "The [Ngulia website](https://a-rocha-kenya.github.io/ngulia-website/) is the public project entry point; ",
  "the [forecast](https://a-rocha-kenya.github.io/ngulia-forcast/) is a separate tool. ",
  "Zenodo and GBIF publication records are in preparation. Source collections and regenerated products are not tracked in Git.\n"
)

citation_authors <- if (length(metadata$authors) == 0) {
  list(list(name = "Ngulia Ringing Project contributors"))
} else {
  purrr::map(metadata$authors, \(x) purrr::compact(list(
    `given-names` = x$given_name,
    `family-names` = x$family_name,
    affiliation = x$affiliation,
    orcid = if (!is.null(x$orcid) && nzchar(x$orcid)) paste0("https://orcid.org/", x$orcid)
  )))
}

citation <- purrr::compact(list(
  `cff-version` = "1.2.0",
  message = metadata$repository$citation_message,
  title = metadata$dataset$title,
  type = "software",
  authors = citation_authors,
  url = if (nzchar(metadata$repository$url)) metadata$repository$url
))

writeLines(readme, "README.md")
yaml::write_yaml(citation, "CITATION.cff")

cli::cli_alert_success("Built README.md and CITATION.cff from publication metadata.")
