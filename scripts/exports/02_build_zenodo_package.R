library(cli)
library(digest)
library(glue)
library(purrr)
library(stringr)

source(here::here("scripts/helpers/data_paths.R"))
source(here::here("scripts/helpers/publication_metadata.R"))
source(here::here("scripts/helpers/publication_references.R"))

# Read publication metadata ----------------------------------------------

metadata <- read_publication_metadata()
bibliography <- read_bibliography_entries(metadata$documents$bibliography)
zenodo_doi <- metadata$zenodo$concept_doi
zenodo_reference <- if (nzchar(zenodo_doi)) {
  glue("deposited under the Zenodo concept DOI https://doi.org/{zenodo_doi}")
} else {
  "prepared for deposit on Zenodo"
}
existing_resource <- if (nzchar(zenodo_doi)) {
  glue("Concept DOI: https://doi.org/{zenodo_doi}\n\nCreate or edit a version within this existing Zenodo resource. Do not enter the concept DOI as the DOI of a specific version.")
} else {
  "No published Zenodo resource is recorded yet. Create a new dataset deposit and add its concept DOI to config/publication/dataset_metadata.yml after publication."
}
paths <- get_data_paths()
output_dir <- paths$zenodo_export_dir
output_path <- file.path(output_dir, "zenodo_form.md")
readme_path <- file.path(output_dir, "README.md")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dataset_documentation <- publication_dataset_documentation(
  metadata$documents$dataset_documentation,
  audience = "zenodo"
)
data_limitations <- read_publication_text(metadata$documents$data_limitations) |>
  stringr::str_remove("^# [^\n]+\n+")

creator_lines <- purrr::map_chr(metadata$authors, \(author) {
  affiliation <- if (!is.null(author$affiliation) && nzchar(author$affiliation)) {
    author$affiliation
  } else {
    "Not specified"
  }
  orcid <- if (!is.null(author$orcid) && nzchar(author$orcid)) {
    paste0("https://orcid.org/", author$orcid)
  } else {
    "Not specified"
  }

  glue(
    "### {author$family_name}, {author$given_name}\n\n",
    "- Affiliation: {affiliation}\n",
    "- ORCID: {orcid}\n"
  )
})

file_lines <- purrr::map_chr(metadata$files, \(file) {
  source_path <- if (!is.null(file$path) && nzchar(file$path)) {
    file$path
  } else {
    file.path("data", "04_curated", file$name)
  }

  glue(
    "- `{source_path}` — upload as `{file$name}`: ",
    "{file$description}"
  )
})
file_lines <- c(
  file_lines,
  "- `exports/zenodo/README.md` — upload as `README.md`: Version-specific dataset documentation and data dictionary."
)

reference_lines <- bibliography |>
  purrr::transpose() |>
  purrr::map_chr(publication_reference_citation)
reference_lines <- paste0("- ", reference_lines)

related_identifier_lines <- publication_related_identifiers(
  bibliography,
  metadata$related_references
) |>
  purrr::map_chr(\(identifier) {
    paste0(
      "- Identifier: ", identifier$identifier, "\n",
      "  - Relation: ", identifier$relation, "\n",
      "  - Resource type: ", identifier$resource_type, "\n",
      "  - Scheme: ", identifier$scheme
    )
  })

funding_lines <- purrr::map_chr(metadata$funding, \(item) {
  glue("- {item$funder}: {item$support}")
})

zenodo_readme <- glue(
  "# {metadata$dataset$data_title}\n\n",
  "{metadata$dataset$data_description}\n\n",
  "This README accompanies the curated CSV files {zenodo_reference}. It documents the tables, columns, ",
  "processing decisions, and interpretation limits for this dataset version.\n\n",
  "The reproducible processing workflow, configuration, and current project documentation ",
  "are maintained at {metadata$repository$url}.\n\n",
  "**License:** Creative Commons Attribution 4.0 International (CC BY 4.0)  \n",
  "**Creators:** {paste(vapply(metadata$authors, publication_author_name, character(1)), collapse = '; ')}\n\n",
  "{dataset_documentation}\n\n",
  "## Interpretation limits\n\n",
  "{data_limitations}\n"
)

form <- glue(
  "# Zenodo form worksheet\n\n",
  "Use the values below when creating or updating the Zenodo record. Do not upload this worksheet as a dataset file.\n\n",
  "## Existing resource\n\n",
  "{existing_resource}\n\n",
  "## Upload type\n\nDataset\n\n",
  "## Title\n\n{metadata$dataset$data_title}\n\n",
  "## Publication date\n\n{format(Sys.Date(), '%Y-%m-%d')}\n\n",
  "## Creators\n\n{paste(creator_lines, collapse = '\n')}\n",
  "## Description\n\n{metadata$dataset$data_description}\n\n",
  "The dataset contains curated bird ringing events, moult observations, daily migration counts, sampling coverage, modeled weather covariates, source-linked operations history, and ring recoveries from Ngulia, Kenya. The uploaded README provides the complete table and column dictionary, processing summary, quality-control description, and interpretation limits. The reproducible processing workflow is available at {metadata$repository$url}.\n\n",
  "## Access right\n\nOpen access\n\n",
  "## License\n\nCreative Commons Attribution 4.0 International (CC BY 4.0)\n\n",
  "## Keywords\n\n{paste0('- ', metadata$dataset$keywords, collapse = '\n')}\n\n",
  "## Language\n\nEnglish\n\n",
  "## Version\n\nLeave blank for the first publication. For later deposits, enter the dataset version or release tag used for this upload.\n\n",
  "## Publisher\n\nZenodo\n\n",
  "## Notes\n\n{metadata$zenodo$notes}\n\n",
  "Interpretation limits: {metadata$dataset$limitations_summary}\n\n",
  "Creator roles: {publication_author_roles_text(metadata$authors)}\n\n",
  "## Funding\n\n{paste(funding_lines, collapse = '\n')}\n\n",
  "## Related identifiers\n\n",
  "- Identifier: {metadata$repository$url}\n",
  "  - Relation: Is supplement to\n",
  "  - Resource type: Software\n",
  "  - Scheme: URL\n",
  "{paste(related_identifier_lines, collapse = '\n')}\n\n",
  "## References\n\n{paste(reference_lines, collapse = '\n')}\n\n",
  "## Files to upload\n\n{paste(file_lines, collapse = '\n')}\n\n",
  "Do not upload raw workbooks, intermediate files, QA logs, website exports, or the GBIF archive to this Zenodo dataset record.\n"
)

unlink(list.files(output_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE), recursive = TRUE)
writeLines(form, output_path)
writeLines(zenodo_readme, readme_path)

upload_dir <- file.path(output_dir, "upload")
dir.create(upload_dir)
source_files <- vapply(metadata$files, \(file) {
  here::here(if (!is.null(file$path) && nzchar(file$path)) file$path else file.path("data", "04_curated", file$name))
}, character(1))
file.copy(c(source_files, readme_path), upload_dir)
upload_files <- file.path(upload_dir, c(vapply(metadata$files, `[[`, character(1), "name"), "README.md"))
manifest <- data.frame(
  file = basename(upload_files),
  bytes = file.info(upload_files)$size,
  sha256 = vapply(upload_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
write.csv(manifest, file.path(output_dir, "upload_manifest.csv"), row.names = FALSE)

cli_alert_success("Wrote six Zenodo upload files, their checksums, and the form worksheet to {output_dir}.")
