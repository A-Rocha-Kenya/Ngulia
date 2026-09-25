read_publication_metadata <- function(path = here::here("config/publication/dataset_metadata.yml")) {
  yaml::read_yaml(path)
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
