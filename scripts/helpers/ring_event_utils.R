as_chr <- function(x) {
  if (inherits(x, "Date")) {
    return(format(x, "%Y-%m-%d"))
  }
  if (inherits(x, "POSIXt")) {
    return(format(x, "%Y-%m-%d %H:%M:%S"))
  }
  as.character(x)
}

blank_to_na <- function(x) {
  x <- str_squish(as_chr(x))
  x[x == "" | str_to_lower(x) %in% c("na", "nan")] <- NA_character_
  x
}

split_preserve_empty <- function(x, delimiter = "|") {
  n_parts <- str_count(x, fixed(delimiter)) + 1L
  parts <- strsplit(x, delimiter, fixed = TRUE)[[1]]
  length(parts) <- n_parts
  parts[is.na(parts)] <- ""
  parts
}

clean_key <- function(x) {
  blank_to_na(x) |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

clean_number_key <- function(x) {
  blank_to_na(x) |>
    str_replace_all("[.]0+$", "") |>
    str_replace_all("[^0-9]+", "")
}

clean_signed_number_key <- function(x) {
  blank_to_na(x) |>
    str_replace_all("[.]0+$", "") |>
    str_replace_all("[^0-9-]+", "") |>
    str_replace_all("(?<!^)-", "") |>
    str_replace("^-+$", "")
}

clean_species_lookup_input <- function(input_text, input_type) {
  if_else(
    input_type %in% c("afring_number", "ngulia_number"),
    if_else(
      input_type == "afring_number",
      clean_signed_number_key(input_text),
      clean_number_key(input_text)
    ),
    clean_key(input_text)
  )
}

assign_daily_count_date <- function(datetime, cutoff_hour = 20L) {
  if (inherits(datetime, "POSIXt")) {
    date <- as.Date(datetime)
    late_rows <- !is.na(datetime) & hour(datetime) >= cutoff_hour
    date[late_rows] <- date[late_rows] + 1
    return(date)
  }

  datetime_text <- blank_to_na(datetime)
  has_time <- !is.na(datetime_text) & str_detect(datetime_text, "T")
  date <- as.Date(rep(NA_character_, length(datetime_text)))

  if (any(has_time)) {
    parsed_datetime <- suppressWarnings(ymd_hms(datetime_text[has_time], tz = "UTC"))
    timed_date <- as.Date(parsed_datetime)
    late_rows <- !is.na(parsed_datetime) & hour(parsed_datetime) >= cutoff_hour
    timed_date[late_rows] <- timed_date[late_rows] + 1
    date[has_time] <- timed_date
  }

  if (any(!has_time)) {
    date[!has_time] <- suppressWarnings(as.Date(datetime_text[!has_time]))
  }

  date
}

assign_season_from_date <- function(date) {
  if (inherits(date, "POSIXt")) {
    date <- as.Date(date)
  } else if (!inherits(date, "Date")) {
    date <- suppressWarnings(as.Date(date))
  }

  # Ngulia ringing seasons run across the calendar-year boundary.
  # Use June 1 as a safe administrative boundary after the January ringing
  # season has ended and before the next October-January season begins.
  year(date) - if_else(
    month(date) < 6L,
    1L,
    0L
  )
}

abort_on_duplicate_keys <- function(data, keys, label, path = NULL) {
  duplicates <- data |>
    count(across(all_of(keys)), name = "n") |>
    filter(n > 1)

  if (nrow(duplicates) == 0) {
    return(invisible(data))
  }

  duplicate_text <- duplicates |>
    unite("key", all_of(keys), sep = " | ", remove = FALSE, na.rm = FALSE) |>
    transmute(line = paste0(key, " (n=", n, ")")) |>
    pull(line)

  cli_abort(c(
    "{label} has duplicate keys after cleaning.",
    if (!is.null(path)) paste0("File: ", path),
    "i" = "Fix the config file before rerunning.",
    setNames(duplicate_text, rep("x", length(duplicate_text)))
  ))
}

abort_on_invalid_rows <- function(data, condition, label, detail_col = NULL, path = NULL) {
  invalid_rows <- data |>
    filter({{ condition }})

  if (nrow(invalid_rows) == 0) {
    return(invisible(data))
  }

  detail_text <- if (is.null(detail_col)) {
    rep("invalid row", nrow(invalid_rows))
  } else {
    invalid_rows[[detail_col]]
  }

  cli_abort(c(
    "{label} contains invalid rows after cleaning.",
    if (!is.null(path)) paste0("File: ", path),
    "i" = "Fix the config file before rerunning.",
    setNames(detail_text, rep("x", length(detail_text)))
  ))
}

abort_on_parse_problems <- function(problems_df, label, path = NULL) {
  if (nrow(problems_df) == 0) {
    return(invisible(problems_df))
  }

  problem_text <- problems_df |>
    transmute(
      line = paste0(
        "row ", row,
        ", col ", col,
        ": expected ", expected,
        ", got ", actual
      )
    ) |>
    pull(line)

  cli_abort(c(
    "{label} has CSV parsing problems.",
    if (!is.null(path)) paste0("File: ", path),
    "i" = "Fix the config file before rerunning.",
    setNames(problem_text, rep("x", length(problem_text)))
  ))
}
