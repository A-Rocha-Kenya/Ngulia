library(yaml)
library(stringr)
library(purrr)
library(glue)
library(cli)

source("scripts/helpers/publication_metadata.R")

metadata <- read_publication_metadata()
dataset_documentation <- publication_dataset_documentation(
  metadata$documents$dataset_documentation,
  audience = "github"
)
data_limitations <- read_publication_text(metadata$documents$data_limitations) |>
  stringr::str_remove("^# [^\n]+\n+")
author_table <- publication_author_table(metadata$authors)

readme <- glue(
  "# {metadata$dataset$title}\n\n",
  "{metadata$dataset$description}\n\n",
  "{metadata$repository$website_note}\n\n",
  "## Authors and contributor roles\n\n",
  "Roles describe contributions to this curated dataset and are a project-maintained attribution record.\n\n",
  "{author_table}\n\n",
  "{dataset_documentation}\n\n",
  "## Interpretation limits\n\n",
  "{data_limitations}\n"
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
