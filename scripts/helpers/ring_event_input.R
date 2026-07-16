read_config_csv <- function(path, label, suppress_warnings = FALSE) {
  config_raw <- if (suppress_warnings) {
    suppressWarnings(
      read_csv(
        path,
        show_col_types = FALSE,
        col_types = cols(.default = col_character())
      )
    )
  } else {
    read_csv(
      path,
      show_col_types = FALSE,
      col_types = cols(.default = col_character())
    )
  }

  abort_on_parse_problems(problems(config_raw), label, path)
  config_raw
}

load_file_specs <- function(path) {
  file_specs <- read_config_csv(path, "file_specs") |>
    mutate(
      overwrite_year = as.logical(overwrite_year),
      raw_date_is_ringing_date = as.logical(raw_date_is_ringing_date),
      header_row = as.integer(header_row),
      year_min = as.integer(year_min),
      year_max = as.integer(year_max),
      keep_year_min = as.integer(keep_year_min),
      keep_year_max = as.integer(keep_year_max),
      use_retrap_code = as.logical(use_retrap_code),
      swap_age_sex = as.logical(swap_age_sex),
      max_row = as.integer(max_row),
      fill_time_down_within_day = as.logical(fill_time_down_within_day),
      fat_scale = blank_to_na(fat_scale)
    )

  abort_on_duplicate_keys(
    file_specs,
    c("source_file", "source_sheet"),
    "file_specs",
    path
  )

  abort_on_invalid_rows(
    file_specs |>
      mutate(
        detail = paste0(
          source_file, " | ", source_sheet,
          " | header_row=", header_row,
          " | year_min=", year_min,
          " | year_max=", year_max
        )
      ),
    is.na(source_file) | source_file == "" |
      is.na(source_sheet) | source_sheet == "" |
      is.na(raw_date_is_ringing_date) |
      is.na(header_row) | header_row < 1 |
      is.na(year_min) | is.na(year_max) |
      year_min > year_max |
      (!is.na(keep_year_min) & !is.na(keep_year_max) & keep_year_min > keep_year_max) |
      (!is.na(max_row) & max_row < 1) |
      !fat_scale %in% c("ngulia", "both", "kaiser"),
    "file_specs",
    "detail",
    path
  )

  file_specs
}

load_corrections <- function(path) {
  corrections <- read_config_csv(path, "corrections", suppress_warnings = TRUE)

  if (!"source_row_end" %in% names(corrections)) {
    corrections <- corrections |>
      mutate(source_row_end = NA_integer_)
  }

  corrections <- corrections |>
    mutate(
      source_row = as.integer(source_row),
      source_row_end = as.integer(blank_to_na(source_row_end))
    ) |>
    mutate(
      source_row_end = coalesce(source_row_end, source_row)
    )

  abort_on_duplicate_keys(
    corrections |>
      filter(!is.na(field), field != "", !is.na(source_row)),
    c("source_file", "source_sheet", "source_row", "field"),
    "corrections",
    path
  )

  abort_on_invalid_rows(
    corrections |>
      mutate(
        detail = paste0(
          source_file, " | ", source_sheet,
          " | source_row=", source_row,
          if_else(
            source_row_end != source_row,
            paste0(":", source_row_end),
            ""
          ),
          " | field=", field
        )
      ),
    is.na(source_file) | source_file == "" |
      is.na(source_sheet) | source_sheet == "" |
      is.na(source_row) | source_row < 1 |
      is.na(source_row_end) | source_row_end < source_row |
      is.na(field) | field == "",
    "corrections",
    "detail",
    path
  )

  corrections |>
    rowwise() |>
    mutate(source_row = list(seq.int(source_row, source_row_end))) |>
    ungroup() |>
    tidyr::unnest(source_row) |>
    select(-source_row_end)
}

load_species_lookup <- function(path) {
  species_lookup <- read_config_csv(path, "species_lookup") |>
    transmute(
      input_type,
      input_text = clean_species_lookup_input(input_text, input_type),
      afring_number = clean_signed_number_key(afring_number)
    ) |>
    filter(
      !is.na(input_type),
      !is.na(input_text),
      input_text != "",
      !is.na(afring_number),
      afring_number != ""
    )

  abort_on_duplicate_keys(
    species_lookup,
    c("input_type", "input_text"),
    "species_lookup",
    path
  )

  species_lookup
}

load_species_reference <- function(path) {
  species_reference <- read_config_csv(path, "species_reference") |>
    mutate(
      afring_number = clean_signed_number_key(afring_number),
      ngulia_number = clean_number_key(ngulia_number),
      avibase_id = blank_to_na(avibase_id)
    )

  abort_on_duplicate_keys(
    filter(species_reference, !is.na(afring_number), afring_number != ""),
    "afring_number",
    "species_reference",
    path
  )

  abort_on_duplicate_keys(
    filter(species_reference, !is.na(ngulia_number), ngulia_number != ""),
    "ngulia_number",
    "species_reference",
    path
  )

  species_reference
}

load_subspecies_lookup <- function(path) {
  subspecies_lookup <- read_config_csv(path, "subspecies_lookup") |>
    mutate(
      afring_number = clean_number_key(afring_number),
      note = blank_to_na(note),
      subspecies_avibase_id = blank_to_na(subspecies_avibase_id),
      n_records = suppressWarnings(as.integer(n_records))
    )

  abort_on_duplicate_keys(
    filter(subspecies_lookup, !is.na(note), note != ""),
    c("afring_number", "note"),
    "subspecies_lookup",
    path
  )

  subspecies_lookup
}

load_measurement_ranges <- function(path) {
  measurement_ranges <- read_config_csv(path, "measurement_ranges") |>
    mutate(
      afring_number = if_else(
        afring_number == "all",
        "all",
        clean_signed_number_key(afring_number)
      ),
      across(c(wing_min, wing_max, weight_min, weight_max), as.numeric)
    )

  abort_on_duplicate_keys(measurement_ranges, "afring_number", "measurement_ranges", path)

  abort_on_invalid_rows(
    measurement_ranges |>
      mutate(detail = paste0(
        afring_number,
        " | wing=", wing_min, "-", wing_max,
        " | weight=", weight_min, "-", weight_max
      )),
    is.na(afring_number) |
      is.na(wing_min) | is.na(wing_max) | wing_min >= wing_max |
      is.na(weight_min) | is.na(weight_max) | weight_min >= weight_max,
    "measurement_ranges",
    "detail",
    path
  )

  abort_on_invalid_rows(
    tibble(
      n_global = sum(measurement_ranges$afring_number == "all"),
      detail = paste0(
        "global rows=",
        sum(measurement_ranges$afring_number == "all")
      )
    ),
    n_global != 1,
    "measurement_ranges",
    "detail",
    path
  )

  measurement_ranges
}

load_moult_specs <- function(path) {
  moult_specs <- read_config_csv(path, "moult_specs") |>
    mutate(
      primary_status_col = blank_to_na(primary_status_col),
      n_old_primaries_remaining_col = blank_to_na(n_old_primaries_remaining_col),
      primary_scores_col = blank_to_na(primary_scores_col),
      primary_scores_n = blank_to_na(primary_scores_n),
      secondary_scores_col = blank_to_na(secondary_scores_col),
      tertial_scores_col = blank_to_na(tertial_scores_col),
      tail_scores_col = blank_to_na(tail_scores_col),
      body_scores_col = blank_to_na(body_scores_col),
      note_cols = blank_to_na(note_cols),
      primary_status_scheme = blank_to_na(primary_status_scheme),
      feather_score_scheme = blank_to_na(feather_score_scheme)
    )

  abort_on_duplicate_keys(
    moult_specs,
    c("source_file", "source_sheet"),
    "moult_specs",
    path
  )

  abort_on_invalid_rows(
    moult_specs |>
      mutate(detail = paste0(source_file, " | ", source_sheet)),
    is.na(source_file) | source_file == "" |
      is.na(source_sheet) | source_sheet == "",
    "moult_specs",
    "detail",
    path
  )

  abort_on_invalid_rows(
    moult_specs |>
      mutate(detail = paste0(source_file, " | ", source_sheet, " | ", primary_status_scheme)),
    !is.na(primary_status_scheme) & primary_status_scheme != "ngulia_oasn",
    "moult_specs",
    "detail",
    path
  )

  abort_on_invalid_rows(
    moult_specs |>
      mutate(detail = paste0(source_file, " | ", source_sheet, " | ", feather_score_scheme)),
    is.na(feather_score_scheme) |
      !feather_score_scheme %in% c("ngulia_legacy", "safring"),
    "moult_specs",
    "detail",
    path
  )

  moult_specs
}

normalize_1995_primary_secondary <- function(primary_scores_raw, secondary_scores_raw) {
  primary_clean <- blank_to_na(primary_scores_raw)
  secondary_clean <- blank_to_na(secondary_scores_raw)
  primary_tokens <- lapply(coalesce(primary_clean, ""), split_preserve_empty)

  move_secondary <- vapply(seq_along(primary_tokens), function(i) {
    tokens <- primary_tokens[[i]]

    if (!is.na(secondary_clean[i]) || length(tokens) != 10) {
      return(FALSE)
    }

    first_nine <- str_to_upper(tokens[seq_len(9)])
    last_value <- str_to_upper(tokens[10])

    all(first_nine == "" | str_detect(first_nine, "^[A-Z0-9]$")) &&
      str_detect(last_value, "^[A-Z0-9]{6}$")
  }, logical(1))

  normalized_primary <- primary_scores_raw
  normalized_secondary <- secondary_scores_raw

  if (any(move_secondary)) {
    normalized_primary[move_secondary] <- vapply(primary_tokens[move_secondary], function(tokens) {
      paste(tokens[seq_len(9)], collapse = "|")
    }, character(1))
    normalized_secondary[move_secondary] <- vapply(primary_tokens[move_secondary], function(tokens) {
      str_to_upper(tokens[10])
    }, character(1))
  }

  tibble(
    primary_scores_raw = normalized_primary,
    secondary_scores_raw = normalized_secondary
  )
}

normalize_combined_moult_scores <- function(
  primary_scores_raw,
  secondary_scores_raw,
  tertial_scores_raw
) {
  primary_clean <- blank_to_na(primary_scores_raw)
  secondary_clean <- blank_to_na(secondary_scores_raw)
  tertial_clean <- blank_to_na(tertial_scores_raw)
  combined_primary_secondary <- !is.na(primary_clean) &
    is.na(secondary_clean) &
    str_detect(str_to_upper(primary_clean), "^[A-Z0-9]{9,10}/[A-Z0-9]{6}$")
  combined_all <- !is.na(primary_clean) &
    is.na(secondary_clean) &
    is.na(tertial_clean) &
    str_detect(str_to_upper(primary_clean), "^[A-Z0-9]{9,10}/[A-Z0-9]{6}/[A-Z0-9]{3}$")

  if (any(combined_primary_secondary)) {
    parts <- str_split_fixed(primary_clean[combined_primary_secondary], fixed("/"), 2)
    primary_scores_raw[combined_primary_secondary] <- parts[, 1]
    secondary_scores_raw[combined_primary_secondary] <- parts[, 2]
  }

  if (any(combined_all)) {
    parts <- str_split_fixed(primary_clean[combined_all], fixed("/"), 3)
    primary_scores_raw[combined_all] <- parts[, 1]
    secondary_scores_raw[combined_all] <- parts[, 2]
    tertial_scores_raw[combined_all] <- parts[, 3]
  }

  tibble(
    primary_scores_raw = primary_scores_raw,
    secondary_scores_raw = secondary_scores_raw,
    tertial_scores_raw = tertial_scores_raw
  )
}

clean_header_key <- function(x) {
  x |>
    as_chr() |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "")
}

first_existing_col <- function(data, candidates) {
  header_keys <- clean_header_key(names(data))
  candidate_keys <- clean_header_key(candidates)
  match_index <- match(candidate_keys, header_keys)
  match_index <- match_index[!is.na(match_index)]
  if (length(match_index) == 0) NA_character_ else names(data)[match_index[1]]
}

resolve_col_override <- function(data, override) {
  override <- blank_to_na(override)
  if (is.na(override)) {
    return(NA_character_)
  }

  override_index <- suppressWarnings(as.integer(override))
  if (!is.na(override_index) && override_index >= 1 && override_index <= ncol(data)) {
    return(names(data)[override_index])
  }

  if (override %in% names(data)) {
    return(override)
  }

  NA_character_
}

resolve_col_refs <- function(data, override) {
  override <- blank_to_na(override)
  if (is.na(override)) {
    return(character())
  }

  refs <- str_split(override, ",", simplify = TRUE) |>
    as.character() |>
    str_squish()
  refs <- refs[refs != ""]
  if (length(refs) == 0) {
    return(character())
  }

  resolved <- unlist(lapply(refs, function(ref) {
    if (str_detect(ref, "^[0-9]+:[0-9]+$")) {
      limits <- as.integer(str_split(ref, ":", simplify = TRUE))
      idx <- seq.int(limits[1], limits[2])
      idx <- idx[idx >= 1 & idx <= ncol(data)]
      return(names(data)[idx])
    }

    ref_index <- suppressWarnings(as.integer(ref))
    if (!is.na(ref_index) && ref_index >= 1 && ref_index <= ncol(data)) {
      return(names(data)[ref_index])
    }

    if (ref %in% names(data)) {
      return(ref)
    }

    character()
  }), use.names = FALSE)

  unique(resolved)
}

collapse_cols_raw <- function(data, columns, separator = "|", named = FALSE) {
  if (length(columns) == 0) {
    return(rep(NA_character_, nrow(data)))
  }

  values <- lapply(columns, function(column) blank_to_na(data[[column]]))
  names(values) <- columns

  purrr::pmap_chr(values, function(...) {
    parts <- c(...)
    if (all(is.na(parts))) {
      return(NA_character_)
    }

    if (named) {
      keep <- !is.na(parts)
      return(paste0(columns[keep], "=", parts[keep], collapse = "; "))
    }

    paste(ifelse(is.na(parts), "", parts), collapse = separator)
  })
}

collapse_primary_cols_raw <- function(data, columns) {
  if (length(columns) == 0) {
    return(rep(NA_character_, nrow(data)))
  }

  values <- lapply(columns, function(column) blank_to_na(data[[column]]))

  purrr::pmap_chr(values, function(...) {
    parts <- c(...)
    if (all(is.na(parts))) {
      return(NA_character_)
    }

    if (
      !is.na(parts[1]) &&
        length(parts) > 1 &&
        all(is.na(parts[-1])) &&
        str_detect(str_to_upper(parts[1]), "^[A-Z0-9]{9,11}$")
    ) {
      return(parts[1])
    }

    paste(ifelse(is.na(parts), "", parts), collapse = "|")
  })
}

fill_time_down_within_day <- function(time_raw, date_raw, day_raw, month_raw, year_raw) {
  parsed_date <- parse_date_vector(date_raw, day_raw, month_raw, year_raw)
  tibble(parsed_date = parsed_date, time_raw = time_raw) |>
    group_by(parsed_date) |>
    fill(time_raw, .direction = "down") |>
    ungroup() |>
    pull(time_raw)
}

col_or_na <- function(data, column) {
  if (is.na(column) || !column %in% names(data)) {
    rep(NA_character_, nrow(data))
  } else {
    blank_to_na(data[[column]])
  }
}

parse_year_value <- function(x) {
  x <- suppressWarnings(as.integer(as.numeric(blank_to_na(x))))
  case_when(
    is.na(x) ~ NA_integer_,
    x < 30 ~ 2000L + x,
    x < 100 ~ 1900L + x,
    TRUE ~ x
  )
}

parse_month_value <- function(x) {
  text <- clean_key(x)
  numeric_month <- suppressWarnings(as.integer(as.numeric(text)))
  month_lookup <- c(
    jan = 1L,
    january = 1L,
    oct = 10L,
    october = 10L,
    nov = 11L,
    november = 11L,
    dec = 12L,
    december = 12L
  )
  ifelse(!is.na(numeric_month), numeric_month, unname(month_lookup[text]))
}

excel_date <- function(x) {
  numeric_x <- suppressWarnings(as.numeric(x))
  ifelse(
    !is.na(numeric_x) & numeric_x > 25000 & numeric_x < 60000,
    as.character(as.Date(numeric_x, origin = "1899-12-30")),
    NA_character_
  )
}

parse_date_one <- function(date_raw, day_raw, month_raw, year_raw) {
  date_text <- blank_to_na(date_raw)
  excel_parsed <- excel_date(date_text)
  if (!is.na(excel_parsed)) {
    return(as.Date(excel_parsed))
  }

  if (!is.na(date_text)) {
    parsed <- suppressWarnings(parse_date_time(
      date_text,
      orders = c(
        "ymd HMS",
        "ymd HM",
        "ymd",
        "dmy HMS",
        "dmy HM",
        "dmy",
        "mdy HMS",
        "mdy HM",
        "mdy"
      ),
      tz = "UTC"
    ))
    if (!is.na(parsed)) return(as.Date(parsed))
  }

  day <- suppressWarnings(as.integer(as.numeric(blank_to_na(day_raw))))
  month <- parse_month_value(month_raw)
  year <- parse_year_value(year_raw)
  if (any(is.na(c(day, month, year)))) {
    return(as.Date(NA))
  }
  suppressWarnings(as.Date(sprintf("%04d-%02d-%02d", year, month, day)))
}

parse_date_vector <- function(date_raw, day_raw, month_raw, year_raw) {
  date_text <- blank_to_na(date_raw)
  parsed <- as.Date(rep(NA_character_, length(date_text)))

  numeric_date <- suppressWarnings(as.numeric(date_text))
  excel_index <- !is.na(numeric_date) &
    numeric_date > 25000 &
    numeric_date < 60000
  parsed[excel_index] <- as.Date(
    numeric_date[excel_index],
    origin = "1899-12-30"
  )

  text_index <- is.na(parsed) & !is.na(date_text)
  if (any(text_index)) {
    parsed_text <- suppressWarnings(parse_date_time(
      date_text[text_index],
      orders = c(
        "ymd HMS",
        "ymd HM",
        "ymd",
        "dmy HMS",
        "dmy HM",
        "dmy",
        "mdy HMS",
        "mdy HM",
        "mdy"
      ),
      tz = "UTC"
    ))
    parsed[text_index] <- as.Date(parsed_text)
  }

  fallback_index <- is.na(parsed)
  if (any(fallback_index)) {
    day <- suppressWarnings(as.integer(as.numeric(blank_to_na(day_raw))))
    month <- parse_month_value(month_raw)
    year <- parse_year_value(year_raw)
    complete <- fallback_index & !is.na(day) & !is.na(month) & !is.na(year)
    parsed[complete] <- suppressWarnings(as.Date(sprintf(
      "%04d-%02d-%02d",
      year[complete],
      month[complete],
      day[complete]
    )))
  }

  parsed
}

parse_time_one <- function(time_raw) {
  text <- blank_to_na(time_raw)
  if (is.na(text)) {
    return(NA_character_)
  }

  numeric_time <- suppressWarnings(as.numeric(text))
  if (!is.na(numeric_time)) {
    if (numeric_time == 24) {
      return("00:00")
    }
    if (numeric_time >= 0 && numeric_time < 1) {
      seconds <- round(numeric_time * 24 * 60 * 60)
      return(sprintf("%02d:%02d", seconds %/% 3600, (seconds %% 3600) %/% 60))
    }
    if (numeric_time >= 0 && numeric_time < 24) {
      hour <- floor(numeric_time)
      minute <- round((numeric_time - hour) * 60)
      return(sprintf("%02d:%02d", hour, minute))
    }
    if (numeric_time >= 100 && numeric_time <= 2359) {
      hour <- numeric_time %/% 100
      minute <- numeric_time %% 100
      if (hour < 24 && minute < 60) return(sprintf("%02d:%02d", hour, minute))
    }
  }

  parsed <- suppressWarnings(parse_date_time(
    text,
    orders = c("HMS", "HM", "IMSp", "IMS p"),
    tz = "UTC"
  ))
  if (!is.na(parsed)) format(parsed, "%H:%M") else NA_character_
}

parse_time_vector <- function(time_raw) {
  text <- blank_to_na(time_raw)
  parsed <- rep(NA_character_, length(text))
  numeric_time <- suppressWarnings(as.numeric(text))

  midnight_24_index <- !is.na(numeric_time) & numeric_time == 24
  if (any(midnight_24_index)) {
    parsed[midnight_24_index] <- "00:00"
  }

  excel_index <- !is.na(numeric_time) & numeric_time >= 0 & numeric_time < 1
  if (any(excel_index)) {
    seconds <- round(numeric_time[excel_index] * 24 * 60 * 60)
    parsed[excel_index] <- sprintf(
      "%02d:%02d",
      seconds %/% 3600,
      (seconds %% 3600) %/% 60
    )
  }

  hour_index <- is.na(parsed) &
    !is.na(numeric_time) &
    numeric_time >= 0 &
    numeric_time < 24
  if (any(hour_index)) {
    hour <- floor(numeric_time[hour_index])
    minute <- round((numeric_time[hour_index] - hour) * 60)
    parsed[hour_index] <- sprintf("%02d:%02d", hour, minute)
  }

  hhmm_index <- is.na(parsed) &
    !is.na(numeric_time) &
    numeric_time >= 100 &
    numeric_time <= 2359
  if (any(hhmm_index)) {
    hour <- numeric_time[hhmm_index] %/% 100
    minute <- numeric_time[hhmm_index] %% 100
    valid <- hour < 24 & minute < 60
    parsed[which(hhmm_index)[valid]] <- sprintf(
      "%02d:%02d",
      hour[valid],
      minute[valid]
    )
  }

  text_index <- is.na(parsed) & !is.na(text)
  if (any(text_index)) {
    parsed_text <- suppressWarnings(parse_date_time(
      text[text_index],
      orders = c("HMS", "HM", "IMSp", "IMS p"),
      tz = "UTC"
    ))
    parsed[text_index] <- ifelse(
      is.na(parsed_text),
      NA_character_,
      format(parsed_text, "%H:%M")
    )
  }

  parsed
}

make_headers <- function(header_row) {
  headers <- blank_to_na(unlist(header_row, use.names = FALSE))
  headers[is.na(headers)] <- paste0("unnamed_", which(is.na(headers)))
  make.unique(headers)
}

read_spec <- function(spec, moult_spec = NULL) {
  source_path <- file.path(raw_dir, spec$source_file)
  n_max <- if (is.na(spec$max_row) || spec$max_row <= 0) NULL else spec$max_row
  header_row <- if (is.na(spec$header_row) || spec$header_row < 1) {
    1L
  } else {
    as.integer(spec$header_row)
  }
  use_retrap_code <- if (is.na(spec$use_retrap_code)) {
    TRUE
  } else {
    isTRUE(spec$use_retrap_code)
  }
  swap_age_sex <- if (is.na(spec$swap_age_sex)) {
    FALSE
  } else {
    isTRUE(spec$swap_age_sex)
  }
  fill_time_down <- if (is.na(spec$fill_time_down_within_day)) {
    FALSE
  } else {
    isTRUE(spec$fill_time_down_within_day)
  }
  if (!file.exists(source_path)) {
    cli_warn("Missing raw file: {spec$source_file}")
    return(tibble())
  }

  raw <- suppressWarnings(
    if (is.null(n_max)) {
      read_excel(
        source_path,
        sheet = spec$source_sheet,
        col_names = FALSE,
        .name_repair = "minimal"
      )
    } else {
      read_excel(
        source_path,
        sheet = spec$source_sheet,
        col_names = FALSE,
        n_max = n_max,
        .name_repair = "minimal"
      )
    }
  )
  if (nrow(raw) == 0) {
    return(tibble())
  }

  if (header_row > nrow(raw)) {
    cli_warn("Header row {header_row} is beyond the end of {spec$source_file}")
    return(tibble())
  }

  data <- suppressWarnings(
    if (is.null(n_max)) {
      read_excel(
        source_path,
        sheet = spec$source_sheet,
        skip = header_row - 1L,
        col_names = make_headers(raw[header_row, ]),
        col_types = rep("text", ncol(raw)),
        .name_repair = "minimal"
      )
    } else {
      read_excel(
        source_path,
        sheet = spec$source_sheet,
        skip = header_row - 1L,
        col_names = make_headers(raw[header_row, ]),
        n_max = n_max,
        col_types = rep("text", ncol(raw)),
        .name_repair = "minimal"
      )
    }
  )
  if (nrow(data) == 0) {
    return(tibble())
  }

  ring_col <- first_existing_col(
    data,
    c("Ring", "Ring #", "RING", "ring no", "ring number")
  )
  species_no_col <- first_existing_col(
    data,
    c("SpeciesNo", "Species No", "AFRING #", "AFRING_No", "AFRING No")
  )
  ngulia_col <- first_existing_col(
    data,
    c("Ngulia #", "Ngulia spp #", "Ngulia spp no", "Ngulia No")
  )
  species_label_col <- first_existing_col(
    data,
    c("SPECIES", "Species", "Name", "English")
  )
  age_col <- first_existing_col(data, c("AGE", "Age"))
  sex_col <- first_existing_col(data, c("SEX", "Sex"))
  wing_col <- first_existing_col(data, c("WING", "Wing"))
  weight_col <- first_existing_col(data, c("WEIGHT", "Weight", "Mass"))
  fat_cols <- names(data)[str_starts(clean_header_key(names(data)), "fat")]
  fat_ngulia_col <- if (spec$fat_scale %in% c("ngulia", "both") && length(fat_cols) > 0) {
    fat_cols[1]
  } else {
    NA_character_
  }
  fat_kaiser_col <- if (spec$fat_scale == "both" && length(fat_cols) > 1) {
    fat_cols[2]
  } else if (spec$fat_scale == "kaiser" && length(fat_cols) > 0) {
    fat_cols[length(fat_cols)]
  } else {
    NA_character_
  }
  date_col <- first_existing_col(data, c("Date"))
  day_col <- first_existing_col(data, c("DAY", "Day"))
  month_col <- first_existing_col(data, c("MON", "MONTH", "Month"))
  year_col <- first_existing_col(data, c("YEAR", "Year"))
  time_col <- coalesce(
    resolve_col_override(data, spec$time_col_override),
    first_existing_col(data, c("TIME", "Time", "Hour", "TIM"))
  )
  retrap_code_col <- first_existing_col(data, c("Code", "RETRAP", "Retrap"))
  note_col <- first_existing_col(
    data,
    c("REMARKS", "Remarks", "Notes", "Note", "Comments", "Comment")
  )
  plumage_col <- first_existing_col(data, c("Plumage"))
  race_form_col <- first_existing_col(
    data,
    c("Race / plmge form", "Race", "Form", "Subspecies", "Sub-species")
  )
  moult_spec <- if (is.null(moult_spec) || nrow(moult_spec) == 0) {
    tibble(
      primary_status_col = NA_character_,
      n_old_primaries_remaining_col = NA_character_,
      primary_scores_col = NA_character_,
      primary_scores_n = NA_character_,
      secondary_scores_col = NA_character_,
      tertial_scores_col = NA_character_,
      tail_scores_col = NA_character_,
      body_scores_col = NA_character_,
      note_cols = NA_character_,
      primary_status_scheme = NA_character_,
      feather_score_scheme = NA_character_
    )
  } else {
    moult_spec[1, ]
  }
  primary_status_col <- resolve_col_override(data, moult_spec$primary_status_col)
  n_old_primaries_remaining_col <- resolve_col_override(data, moult_spec$n_old_primaries_remaining_col)
  primary_scores_cols <- resolve_col_refs(data, moult_spec$primary_scores_col)
  secondary_scores_cols <- resolve_col_refs(data, moult_spec$secondary_scores_col)
  tertial_scores_col <- resolve_col_override(data, moult_spec$tertial_scores_col)
  tail_scores_col <- resolve_col_override(data, moult_spec$tail_scores_col)
  body_scores_col <- resolve_col_override(data, moult_spec$body_scores_col)
  moult_note_cols <- resolve_col_refs(data, moult_spec$note_cols)

  out <- tibble(
    source_file = spec$source_file,
    source_sheet = spec$source_sheet,
    source_row = 1L + seq_len(nrow(data)),
    year_min = as.integer(spec$year_min),
    year_max = as.integer(spec$year_max),
    keep_year_min = as.integer(spec$keep_year_min),
    keep_year_max = as.integer(spec$keep_year_max),
    overwrite_year = isTRUE(spec$overwrite_year),
    raw_date_is_ringing_date = isTRUE(spec$raw_date_is_ringing_date),
    date_raw = col_or_na(data, date_col),
    day_raw = col_or_na(data, day_col),
    month_raw = col_or_na(data, month_col),
    year_raw = col_or_na(data, year_col),
    time_raw = col_or_na(data, time_col),
    species_no_raw = col_or_na(data, species_no_col),
    species_ngulia_raw = col_or_na(data, ngulia_col),
    species_label_raw = col_or_na(data, species_label_col),
    age_raw = col_or_na(data, age_col),
    sex_raw = col_or_na(data, sex_col),
    wing_raw = col_or_na(data, wing_col),
    weight_raw = col_or_na(data, weight_col),
    fat_ngulia_raw = col_or_na(data, fat_ngulia_col),
    fat_kaiser_raw = col_or_na(data, fat_kaiser_col),
    ringNumber_raw = col_or_na(data, ring_col),
    retrap_code_raw = if (use_retrap_code) {
      col_or_na(data, retrap_code_col)
    } else {
      rep(NA_character_, nrow(data))
    },
    note_raw = col_or_na(data, note_col),
    plumage_raw = col_or_na(data, plumage_col),
    race_form_raw = col_or_na(data, race_form_col),
    primary_moult_status_raw = col_or_na(data, primary_status_col),
    primary_status_scheme = moult_spec$primary_status_scheme,
    feather_score_scheme = moult_spec$feather_score_scheme,
    old_primaries_raw = col_or_na(data, n_old_primaries_remaining_col),
    primary_scores_n = moult_spec$primary_scores_n,
    primary_scores_raw = collapse_primary_cols_raw(data, primary_scores_cols),
    secondary_scores_raw = if (length(secondary_scores_cols) > 1) {
      collapse_cols_raw(data, secondary_scores_cols, separator = "")
    } else if (length(secondary_scores_cols) == 1) {
      col_or_na(data, secondary_scores_cols[1])
    } else {
      rep(NA_character_, nrow(data))
    },
    tertial_scores_raw = col_or_na(data, tertial_scores_col),
    tail_scores_raw = col_or_na(data, tail_scores_col),
    body_scores_raw = col_or_na(data, body_scores_col),
    moult_note_raw = collapse_cols_raw(data, moult_note_cols, named = TRUE)
  )
  if (swap_age_sex) {
    out <- out |>
      mutate(tmp_age_raw = age_raw, age_raw = sex_raw, sex_raw = tmp_age_raw) |>
      select(-tmp_age_raw)
  }
  if (fill_time_down) {
    out <- out |>
      mutate(
        time_raw = fill_time_down_within_day(
          time_raw,
          date_raw,
          day_raw,
          month_raw,
          year_raw
        )
      )
  }
  out <- out |>
    mutate(
      secondary_scores_raw = if_else(
        source_file == "1995.xls" &
          source_sheet == "Sheet1" &
          clean_key(secondary_scores_raw) == "nomist",
        NA_character_,
        secondary_scores_raw
      )
    )
  if (identical(spec$source_file, "1995.xls") && identical(spec$source_sheet, "Sheet1")) {
    normalized_moult <- normalize_1995_primary_secondary(
      out$primary_scores_raw,
      out$secondary_scores_raw
    )
    out <- out |>
      mutate(
        primary_scores_raw = normalized_moult$primary_scores_raw,
        secondary_scores_raw = normalized_moult$secondary_scores_raw
      )
  }
  normalized_moult <- normalize_combined_moult_scores(
    out$primary_scores_raw,
    out$secondary_scores_raw,
    out$tertial_scores_raw
  )
  out <- out |>
    mutate(
      primary_scores_raw = normalized_moult$primary_scores_raw,
      secondary_scores_raw = normalized_moult$secondary_scores_raw,
      tertial_scores_raw = normalized_moult$tertial_scores_raw
    )
  out <- out |>
    mutate(
      species_raw = coalesce(
        species_no_raw,
        species_ngulia_raw,
        species_label_raw
      ),
      row_has_data = if_any(
        c(
          date_raw,
          day_raw,
          month_raw,
          year_raw,
          time_raw,
          species_raw,
          ringNumber_raw
        ),
        ~ !is.na(.x)
      ),
      repeated_header = clean_key(ringNumber_raw) %in%
        c("ring", "ring no", "ring number", "ringing number") |
        clean_key(species_raw) %in% c("species", "name", "ngulia spp")
    ) |>
    filter(row_has_data, !repeated_header) |>
    select(-row_has_data, -repeated_header)

  out
}

apply_corrections <- function(data, corrections) {
  if (nrow(corrections) == 0) {
    return(data)
  }

  row_actions <- corrections |>
    filter(field == "row_action") |>
    transmute(
      source_file,
      source_sheet,
      source_row = as.integer(source_row),
      row_action = str_to_lower(blank_to_na(corrected_value)),
      row_action_note = blank_to_na(note)
    )

  allowed_fields <- intersect(unique(corrections$field), names(data))
  unknown_fields <- setdiff(
    unique(corrections$field),
    c(names(data), "row_action")
  )
  if (length(unknown_fields) > 0) {
    cli_abort(c(
      "corrections contains unknown fields.",
      "i" = "Fix the config file before rerunning.",
      setNames(unknown_fields, rep("x", length(unknown_fields)))
    ))
  }

  for (field in allowed_fields) {
    field_corrections <- corrections |>
      filter(.data$field == !!field) |>
      transmute(
        source_file,
        source_sheet,
        source_row = as.integer(source_row),
        corrected_value,
        has_correction = TRUE
      )

    data <- data |>
      left_join(
        field_corrections,
        by = c("source_file", "source_sheet", "source_row")
      ) |>
      mutate(
        "{field}" := if_else(
          !is.na(has_correction),
          corrected_value,
          .data[[field]]
        )
      ) |>
      select(-corrected_value, -has_correction)
  }

  data |>
    left_join(
      row_actions,
      by = c("source_file", "source_sheet", "source_row")
    ) |>
    mutate(
      species_raw = coalesce(
        species_no_raw,
        species_ngulia_raw,
        species_label_raw
      )
    )
}
