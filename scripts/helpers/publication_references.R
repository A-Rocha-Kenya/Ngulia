read_bibliography_entries <- function(path) {
  entries <- stringr::str_split(readr::read_file(path), "(?m)^@")[[1]] |>
    purrr::discard(~ !nzchar(.x))
  entries <- paste0("@", entries)

  field <- function(entry, name) {
    match <- stringr::str_match(
      entry,
      stringr::regex(paste0("(?s)\\n\\s*", name, "\\s*=\\s*\\{(.*?)\\}\\s*,?"))
    )
    stringr::str_squish(match[, 2])
  }

  purrr::map_dfr(entries, \(entry) {
    tibble::tibble(
      citekey = stringr::str_match(entry, "^@\\w+\\{([^,]+),")[, 2],
      author = field(entry, "author"),
      title = field(entry, "title"),
      journal = field(entry, "journal"),
      year = field(entry, "year"),
      doi = field(entry, "doi"),
      url = field(entry, "url")
    )
  }) |>
    dplyr::mutate(dplyr::across(-citekey, ~ dplyr::na_if(.x, "")))
}

publication_reference_citation <- function(reference) {
  citation <- paste(
    reference$author,
    paste0("(", reference$year, ")"),
    reference$title,
    reference$journal,
    sep = ". "
  )
  identifier <- dplyr::coalesce(
    ifelse(!is.na(reference$doi), paste0("https://doi.org/", reference$doi), NA_character_),
    reference$url
  )

  stringr::str_squish(paste(c(citation, identifier)[!is.na(c(citation, identifier))], collapse = " "))
}

publication_reference_markdown <- function(references, selected) {
  rows <- purrr::map_chr(selected, \(selection) {
    reference <- references |>
      dplyr::filter(citekey == selection$citekey) |>
      dplyr::slice(1)
    glue::glue("- **{reference$citekey}** — {publication_reference_citation(reference)}  \n  {selection$purpose}")
  })

  paste(rows, collapse = "\n")
}

publication_related_identifiers <- function(references, selected) {
  purrr::map(selected, \(selection) {
    reference <- references |>
      dplyr::filter(citekey == selection$citekey) |>
      dplyr::slice(1)
    identifier <- dplyr::coalesce(
      if (!is.na(reference$doi)) paste0("10.", stringr::str_remove(reference$doi, "^10\\.")) else NA_character_,
      stringr::str_extract(reference$url, "https?://\\S+")
    )

    if (is.na(identifier)) return(NULL)

    list(
      identifier = identifier,
      relation = selection$relation,
      resource_type = "publication-article",
      scheme = if (!is.na(reference$doi)) "doi" else "url"
    )
  }) |>
    purrr::compact()
}
