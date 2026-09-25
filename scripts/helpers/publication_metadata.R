read_publication_metadata <- function(path = here::here("config/publication/dataset_metadata.yml")) {
  yaml::read_yaml(path)
}

read_publication_text <- function(path) {
  paste(readLines(here::here(path), warn = FALSE), collapse = "\n")
}

publication_dataset_documentation <- function(path, audience = c("github", "zenodo")) {
  audience <- match.arg(audience)
  documentation <- read_publication_text(path)

  if (audience == "zenodo") {
    documentation <- stringr::str_remove_all(
      documentation,
      stringr::regex("<!-- github-only:start -->.*?<!-- github-only:end -->\\s*", dotall = TRUE)
    )
    documentation <- publication_strip_local_links(documentation)
  } else {
    documentation <- stringr::str_remove_all(
      documentation,
      "<!-- github-only:(start|end) -->\\n?"
    )
  }

  stringr::str_trim(documentation)
}

publication_strip_local_links <- function(text) {
  stringr::str_replace_all(text, "\\[([^]]+)\\]\\((?!https?://|mailto:|#)[^)]+\\)", "\\1")
}

xml_escape <- function(x) {
  x |>
    stringr::str_replace_all("&", "&amp;") |>
    stringr::str_replace_all("<", "&lt;") |>
    stringr::str_replace_all(">", "&gt;") |>
    stringr::str_replace_all('"', "&quot;") |>
    stringr::str_replace_all("'", "&apos;")
}

publication_file_table <- function(files) {
  file_rows <- purrr::map_chr(files, \(x) glue::glue("| `{x$name}` | {x$description} |"))
  paste(c("| File | Description |", "| --- | --- |", file_rows), collapse = "\n")
}

publication_author_name <- function(author) {
  stringr::str_squish(paste(author$given_name, author$family_name))
}

publication_author_table <- function(authors) {
  author_rows <- purrr::map_chr(authors, \(x) {
    roles <- paste(x$roles, collapse = "; ")
    glue::glue("| {publication_author_name(x)} | {roles} |")
  })

  paste(c("| Creator | Roles |", "| --- | --- |", author_rows), collapse = "\n")
}

publication_author_roles_text <- function(authors) {
  purrr::map_chr(authors, \(x) {
    glue::glue("{publication_author_name(x)}: {paste(x$roles, collapse = '; ')}.")
  }) |>
    paste(collapse = " ")
}
