build_ring_event_id <- function(ring_number, datetime, precision = "datetime") {
  datetime_key <- str_replace_all(as.character(datetime), "[^0-9]", "")
  datetime_key <- str_sub(datetime_key, 1, 8)
  paste0(ring_number, "__", datetime_key)
}

assign_ring_event_ids <- function(data) {
  data |>
    mutate(
      ringing_date_text = format(ringing_date, "%Y-%m-%d"),
      event_datetime_text = if_else(
        datetime_precision == "date",
        format(parsed_date, "%Y-%m-%d"),
        format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      ),
      ring_event_id_base = if_else(
        clean_required,
        build_ring_event_id(ringNumber, ringing_date_text, "date"),
        NA_character_
      ),
      ring_event_id_full = if_else(
        clean_required,
        paste0(
          ringNumber,
          "__",
          str_replace_all(event_datetime_text, "[^0-9A-Za-z]", "")
        ),
        NA_character_
      )
    ) |>
    add_count(ring_event_id_base, name = "n_ring_event_id_base") |>
    mutate(
      ring_event_id = if_else(
        clean_required & n_ring_event_id_base > 1,
        ring_event_id_full,
        ring_event_id_base
      )
    ) |>
    select(-ringing_date_text, -event_datetime_text, -ring_event_id_base, -ring_event_id_full, -n_ring_event_id_base)
}

resolve_event_row_id <- function(data, same_day_groups) {
  data |>
    left_join(
      same_day_groups |>
        select(ringNumber, ringing_date, merged_row_id),
      by = c("ringNumber", "ringing_date")
    ) |>
    mutate(event_row_id = coalesce(merged_row_id, row_id)) |>
    select(-merged_row_id)
}

decode_old_primaries_value <- function(x) {
  x_clean <- blank_to_na(x)
  if (is.na(x_clean)) {
    return(list(value = NA_integer_, invalid = FALSE, note = NA_character_))
  }

  mapped <- suppressWarnings(as.integer(as.numeric(x_clean)))
  if (!is.na(mapped) && mapped >= 0L && mapped <= 10L) {
    return(list(value = mapped, invalid = FALSE, note = NA_character_))
  }

  list(
    value = NA_integer_,
    invalid = TRUE,
    note = paste0("old_primaries_raw=", x_clean)
  )
}

parse_expected_lengths <- function(x, default = 10L) {
  x_clean <- blank_to_na(x)
  if (is.na(x_clean)) {
    return(default)
  }

  lengths <- str_split(x_clean, ",", simplify = TRUE) |>
    as.character() |>
    str_squish()
  lengths <- lengths[lengths != ""]
  lengths <- suppressWarnings(as.integer(lengths))
  lengths <- lengths[!is.na(lengths)]

  if (length(lengths) == 0) default else unique(lengths)
}

normalize_feather_tokens <- function(tokens, scheme) {
  normalized <- str_to_upper(str_squish(tokens))
  normalized[normalized == ""] <- NA_character_

  if (identical(scheme, "ngulia_legacy")) {
    normalized[normalized == "O"] <- "0"
    normalized[normalized == "N"] <- "5"
    normalized[normalized %in% c("9", "S")] <- "S"
    valid_tokens <- c(as.character(0:5), "S")
  } else {
    valid_tokens <- c(as.character(0:5), "8")
  }

  unknown <- !is.na(normalized) & !normalized %in% valid_tokens
  normalized[unknown] <- NA_character_

  list(values = normalized, unknown = unknown)
}

derive_primary_moult_status <- function(tokens) {
  if (length(tokens) == 0 || any(is.na(tokens)) || !all(tokens %in% as.character(0:5))) {
    return(NA_character_)
  }
  if (any(tokens %in% as.character(1:4))) {
    return("active")
  }
  if (all(tokens == "0")) {
    return("old")
  }
  if (all(tokens == "5")) {
    return("complete")
  }
  "suspended"
}

decode_primary_scores <- function(raw, expected_lengths, feather_score_scheme) {
  raw_clean <- blank_to_na(raw)
  out_names <- paste0("P", seq_len(10))
  empty_values <- setNames(as.list(rep(NA_character_, 10)), out_names)
  allowed_lengths <- unique(c(expected_lengths, if (10L %in% expected_lengths) 9L))

  if (is.na(raw_clean)) {
    return(c(
      empty_values,
      list(
        invalid = FALSE,
        note = NA_character_,
        primary_sequence_status = NA_character_
      )
    ))
  }

  normalized <- raw_clean
  normalization_note <- NA_character_
  if (identical(normalized, "0")) {
    normalized <- str_dup("0", max(allowed_lengths))
    normalization_note <- paste0("primary_scores_raw=0; normalized=", normalized)
  } else if (10L %in% allowed_lengths && str_detect(normalized, "^([0-5])\\1{10}$")) {
    normalized <- str_sub(normalized, 1, 10)
    normalization_note <- paste0("primary_scores_raw=", raw_clean, "; normalized=", normalized)
  }

  tokens <- if (str_detect(normalized, fixed("|"))) {
    split_preserve_empty(normalized)
  } else {
    strsplit(normalized, "", fixed = TRUE)[[1]]
  }

  tokens <- str_to_upper(str_squish(tokens))
  tokens[tokens == ""] <- NA_character_
  if (!length(tokens) %in% allowed_lengths) {
    return(c(
      empty_values,
      list(
        invalid = TRUE,
        note = paste0("primary_scores_raw=", raw_clean),
        primary_sequence_status = NA_character_
      )
    ))
  }

  normalized_result <- normalize_feather_tokens(tokens, feather_score_scheme)
  normalized_tokens <- normalized_result$values
  unknown <- normalized_result$unknown

  values <- rep(NA_character_, 10)
  values[seq_along(normalized_tokens)] <- normalized_tokens
  values <- as.list(values)
  names(values) <- out_names

  legacy_alias <- feather_score_scheme == "ngulia_legacy" &
    any(tokens %in% c("N", "O", "9"), na.rm = TRUE)
  if (legacy_alias) {
    normalization_note <- join_note_parts(c(
      normalization_note,
      paste0("primary_scores_raw=", raw_clean, "; normalized_legacy_codes")
    ))
  }
  if (any(unknown)) {
    normalization_note <- join_note_parts(c(
      normalization_note,
      paste0("primary_scores_raw=", raw_clean)
    ))
  }

  c(
    values,
    list(
      invalid = any(unknown),
      note = normalization_note,
      primary_sequence_status = derive_primary_moult_status(normalized_tokens)
    )
  )
}

decode_moult_token_string <- function(x, expected_n, label, feather_score_scheme) {
  x_clean <- str_to_upper(str_squish(x))
  if (identical(x_clean, "ALL O")) {
    x_clean <- str_dup("O", expected_n)
  }

  tokens <- strsplit(x_clean, "", fixed = TRUE)[[1]]
  if (length(tokens) != expected_n) {
    return(list(
      values = rep(NA_character_, expected_n),
      invalid = TRUE,
      note = paste0(label, "_scores_raw=", x)
    ))
  }

  normalized_result <- normalize_feather_tokens(tokens, feather_score_scheme)
  normalized <- normalized_result$values
  unknown <- normalized_result$unknown
  note <- if (any(unknown)) {
    paste0(label, "_scores_raw=", x)
  } else if (feather_score_scheme == "ngulia_legacy" && any(tokens %in% c("N", "O", "9"))) {
    paste0(label, "_scores_raw=", x, "; normalized_legacy_codes")
  } else {
    NA_character_
  }

  list(values = normalized, invalid = any(unknown), note = note)
}

decode_secondary_tail_values <- function(secondary_raw, tertial_raw, tail_raw, feather_score_scheme) {
  secondary_clean <- blank_to_na(secondary_raw)
  tertial_clean <- blank_to_na(tertial_raw)
  tail_clean <- blank_to_na(tail_raw)
  secondary_names <- paste0("S", seq_len(6))
  tertial_names <- paste0("T", seq_len(3))
  tail_names <- paste0("Tail", seq_len(6))
  output <- c(
    setNames(as.list(rep(NA_character_, 6)), secondary_names),
    setNames(as.list(rep(NA_character_, 3)), tertial_names),
    setNames(as.list(rep(NA_character_, 6)), tail_names),
    list(
      secondary_invalid = FALSE,
      tertial_invalid = FALSE,
      tail_invalid = FALSE,
      secondary_note = NA_character_,
      tertial_note = NA_character_,
      tail_note = NA_character_
    )
  )

  if (!is.na(secondary_clean)) {
    secondary_clean <- str_to_upper(secondary_clean)
    if (str_detect(secondary_clean, "/")) {
      parts <- strsplit(secondary_clean, "/", fixed = TRUE)[[1]]
      if (length(parts) == 2) {
        secondary_result <- decode_moult_token_string(parts[1], 6, "secondary", feather_score_scheme)
        tertial_result <- decode_moult_token_string(parts[2], 3, "tertial", feather_score_scheme)
        output[secondary_names] <- as.list(secondary_result$values)
        output[tertial_names] <- as.list(tertial_result$values)
        output$secondary_invalid <- secondary_result$invalid
        output$tertial_invalid <- tertial_result$invalid
        output$secondary_note <- secondary_result$note
        output$tertial_note <- tertial_result$note
      } else {
        output$secondary_invalid <- TRUE
        output$secondary_note <- paste0("secondary_scores_raw=", secondary_clean)
      }
    } else if (is.na(tertial_clean) && str_detect(secondary_clean, "^[A-Z0-9]{9}$")) {
      secondary_result <- decode_moult_token_string(str_sub(secondary_clean, 1, 6), 6, "secondary", feather_score_scheme)
      tertial_result <- decode_moult_token_string(str_sub(secondary_clean, 7, 9), 3, "tertial", feather_score_scheme)
      output[secondary_names] <- as.list(secondary_result$values)
      output[tertial_names] <- as.list(tertial_result$values)
      output$secondary_invalid <- secondary_result$invalid
      output$tertial_invalid <- tertial_result$invalid
      output$secondary_note <- secondary_result$note
      output$tertial_note <- tertial_result$note
    } else {
      secondary_result <- decode_moult_token_string(secondary_clean, 6, "secondary", feather_score_scheme)
      output[secondary_names] <- as.list(secondary_result$values)
      output$secondary_invalid <- secondary_result$invalid
      output$secondary_note <- secondary_result$note
    }
  }

  if (!is.na(tertial_clean)) {
    tertial_clean <- str_to_upper(tertial_clean)
    tertial_result <- decode_moult_token_string(tertial_clean, 3, "tertial", feather_score_scheme)
    if (!tertial_result$invalid) {
      existing_values <- unlist(output[tertial_names], use.names = FALSE)
      if (all(is.na(existing_values))) {
        output[tertial_names] <- as.list(tertial_result$values)
        output$tertial_note <- tertial_result$note
      } else if (!identical(existing_values, tertial_result$values)) {
        output$tertial_invalid <- TRUE
        output$tertial_note <- paste0("tertial_scores_raw=", tertial_clean)
        output[tertial_names] <- as.list(rep(NA_character_, 3))
      }
    } else {
      output$tertial_invalid <- TRUE
      output$tertial_note <- tertial_result$note
      output[tertial_names] <- as.list(tertial_result$values)
    }
  }

  if (!is.na(tail_clean)) {
    tail_clean <- str_to_upper(tail_clean)
    if (identical(tail_clean, "9")) {
      output$tail_invalid <- TRUE
      output$tail_note <- "tail_scores_raw=9; feather_position_unresolved"
    } else {
      tail_result <- decode_moult_token_string(tail_clean, 6, "tail", feather_score_scheme)
      output[tail_names] <- as.list(tail_result$values)
      output$tail_invalid <- tail_result$invalid
      output$tail_note <- tail_result$note
    }
  }

  output
}

decode_structured_moult_note <- function(raw, feather_score_scheme) {
  raw_clean <- blank_to_na(raw)
  secondary_names <- paste0("S", seq_len(6))
  tertial_names <- paste0("T", seq_len(3))
  secondary_scalar_pattern <- "(?:([1-6])\\.1|S([1-6]))\\s*=\\s*([0-5NO89S])"
  secondary_block_pattern <- "(?:1\\.1|S1)\\s*=\\s*([0-5NO89S]{1,6})"
  tertial_pattern <- "(?:1\\.2|T1)\\s*=\\s*([0-5NO89S])"
  output <- c(
    setNames(as.list(rep(NA_character_, 6)), secondary_names),
    setNames(as.list(rep(NA_character_, 3)), tertial_names),
    list(invalid = FALSE, note = raw_clean)
  )

  if (is.na(raw_clean)) {
    return(output)
  }

  note_text <- raw_clean |> str_squish()
  scalar_matches <- str_match_all(note_text, secondary_scalar_pattern)[[1]]
  block_match <- str_match(note_text, secondary_block_pattern)
  tertial_match <- str_match(note_text, tertial_pattern)

  if (nrow(scalar_matches) == 6) {
    values <- rep(NA_character_, 6)
    secondary_idx <- coalesce(
      suppressWarnings(as.integer(scalar_matches[, 2])),
      suppressWarnings(as.integer(scalar_matches[, 3]))
    )
    normalized <- normalize_feather_tokens(scalar_matches[, 4], feather_score_scheme)
    if (!any(normalized$unknown)) {
      values[secondary_idx] <- normalized$values
      output[secondary_names] <- as.list(values)
      note_text <- str_remove_all(note_text, paste0(secondary_scalar_pattern, "\\s*;?"))
    } else {
      output$invalid <- TRUE
    }
  } else if (!is.na(block_match[1, 2])) {
    values <- strsplit(block_match[1, 2], "", fixed = TRUE)[[1]]
    normalized <- normalize_feather_tokens(values, feather_score_scheme)
    if (!any(normalized$unknown)) {
      output[secondary_names[seq_along(values)]] <- as.list(normalized$values)
      note_text <- str_remove(note_text, paste0(secondary_block_pattern, "\\s*;?"))
    } else {
      output$invalid <- TRUE
    }
  }

  if (!is.na(tertial_match[1, 2])) {
    normalized <- normalize_feather_tokens(tertial_match[1, 2], feather_score_scheme)
    if (!any(normalized$unknown)) {
      output[["T1"]] <- normalized$values
      note_text <- str_remove(note_text, paste0(tertial_pattern, "\\s*;?"))
    } else {
      output$invalid <- TRUE
    }
  }

  note_text <- note_text |>
    str_replace_all("^\\s*;\\s*|\\s*;\\s*$", "") |>
    str_replace_all("\\s*;\\s*;+", "; ") |>
    str_squish()
  note_text <- blank_to_na(note_text)

  output$note <- note_text
  output
}

decode_status_values <- function(x, scheme) {
  x_clean <- blank_to_na(x)
  x_clean[x_clean == "?"] <- NA_character_
  mapped <- case_when(
    scheme == "ngulia_oasn" & x_clean == "0" ~ "old",
    scheme == "ngulia_oasn" & x_clean == "1" ~ "active",
    scheme == "ngulia_oasn" & x_clean == "2" ~ "suspended",
    scheme == "ngulia_oasn" & x_clean == "5" ~ "complete",
    TRUE ~ NA_character_
  )
  invalid <- !is.na(x_clean) & is.na(mapped)

  tibble(
    reported_primary_moult_status = mapped,
    status_invalid = invalid,
    status_note = if_else(invalid, paste0("primary_moult_status_raw=", x_clean), NA_character_)
  )
}

decode_body_values <- function(x) {
  x_clean <- blank_to_na(x)
  output <- tibble(
    body_moult_head = NA_integer_,
    body_moult_upperparts = NA_integer_,
    body_moult_underparts = NA_integer_,
    body_invalid = FALSE,
    body_note = NA_character_
  )
  if (is.na(x_clean)) {
    return(output)
  }

  normalized <- if (identical(x_clean, "0")) "000" else x_clean
  if (!str_detect(normalized, "^[0-3]{3}$")) {
    output$body_invalid <- TRUE
    output$body_note <- paste0("body_moult_raw=", x_clean)
    return(output)
  }

  values <- as.integer(strsplit(normalized, "", fixed = TRUE)[[1]])
  output$body_moult_head <- values[1]
  output$body_moult_upperparts <- values[2]
  output$body_moult_underparts <- values[3]
  if (x_clean != normalized) {
    output$body_note <- paste0("body_moult_raw=", x_clean, "; normalized=", normalized)
  }
  output
}

decode_old_primaries_values <- function(x) {
  x_clean <- blank_to_na(x)
  mapped <- suppressWarnings(as.integer(as.numeric(x_clean)))
  valid <- !is.na(mapped) & mapped >= 0L & mapped <= 10L

  tibble(
    n_old_primaries_remaining = if_else(valid, mapped, NA_integer_),
    old_primaries_invalid = !is.na(x_clean) & !valid,
    old_primaries_note = if_else(old_primaries_invalid, paste0("old_primaries_raw=", x_clean), NA_character_)
  )
}

decode_primary_key <- function(primary_scores_raw, primary_scores_n, feather_score_scheme) {
  primary_lengths <- parse_expected_lengths(primary_scores_n, default = 10L)
  primary_result <- decode_primary_scores(primary_scores_raw, primary_lengths, feather_score_scheme)

  tibble(
    !!!primary_result[paste0("P", seq_len(10))],
    primary_invalid = isTRUE(primary_result$invalid),
    primary_note = primary_result$note,
    primary_sequence_status = primary_result$primary_sequence_status
  )
}

decode_secondary_key <- function(secondary_scores_raw, tertial_scores_raw, tail_scores_raw, feather_score_scheme) {
  secondary_result <- decode_secondary_tail_values(
    secondary_scores_raw,
    tertial_scores_raw,
    tail_scores_raw,
    feather_score_scheme
  )

  tibble(
    !!!secondary_result[paste0("S", seq_len(6))],
    !!!secondary_result[paste0("T", seq_len(3))],
    !!!secondary_result[paste0("Tail", seq_len(6))],
    secondary_invalid = isTRUE(secondary_result$secondary_invalid),
    tertial_invalid = isTRUE(secondary_result$tertial_invalid),
    tail_invalid = isTRUE(secondary_result$tail_invalid),
    secondary_note = secondary_result$secondary_note,
    tertial_note = secondary_result$tertial_note,
    tail_note = secondary_result$tail_note
  )
}

decode_moult_note_key <- function(moult_note_raw, feather_score_scheme) {
  note_result <- decode_structured_moult_note(moult_note_raw, feather_score_scheme)

  tibble(
    !!!setNames(note_result[paste0("S", seq_len(6))], paste0("note_S", seq_len(6))),
    !!!setNames(note_result[paste0("T", seq_len(3))], paste0("note_T", seq_len(3))),
    moult_note_remainder = note_result$note,
    moult_note_invalid = isTRUE(note_result$invalid)
  )
}

append_note_column <- function(note, extra) {
  extra <- blank_to_na(extra)
  case_when(
    is.na(note) ~ extra,
    is.na(extra) ~ note,
    TRUE ~ paste(note, extra, sep = "|")
  )
}

parse_moult_observations <- function(observations) {
  primary_lookup_keys <- observations |>
    distinct(primary_scores_raw, primary_scores_n, feather_score_scheme)
  primary_lookup <- bind_cols(
    primary_lookup_keys,
    purrr::pmap_dfr(primary_lookup_keys, decode_primary_key)
  )

  secondary_lookup_keys <- observations |>
    distinct(secondary_scores_raw, tertial_scores_raw, tail_scores_raw, feather_score_scheme)
  secondary_lookup <- bind_cols(
    secondary_lookup_keys,
    purrr::pmap_dfr(secondary_lookup_keys, decode_secondary_key)
  )

  note_lookup_keys <- observations |>
    distinct(moult_note_raw, feather_score_scheme)
  note_lookup <- bind_cols(
    note_lookup_keys,
    purrr::pmap_dfr(note_lookup_keys, decode_moult_note_key)
  )

  body_lookup_keys <- observations |>
    distinct(body_scores_raw) |>
    select(body_scores_raw)
  body_lookup <- bind_cols(
    body_lookup_keys,
    purrr::map_dfr(body_lookup_keys$body_scores_raw, decode_body_values)
  )

  parsed <- observations |>
    bind_cols(decode_status_values(
      observations$primary_moult_status_raw,
      observations$primary_status_scheme
    )) |>
    bind_cols(decode_old_primaries_values(observations$old_primaries_raw)) |>
    left_join(
      primary_lookup,
      by = c("primary_scores_raw", "primary_scores_n", "feather_score_scheme")
    ) |>
    left_join(
      secondary_lookup,
      by = c(
        "secondary_scores_raw",
        "tertial_scores_raw",
        "tail_scores_raw",
        "feather_score_scheme"
      )
    ) |>
    left_join(
      body_lookup,
      by = "body_scores_raw"
    ) |>
    left_join(
      note_lookup,
      by = c("moult_note_raw", "feather_score_scheme")
    ) |>
    mutate(
      primary_status_inconsistent = !is.na(reported_primary_moult_status) &
        !is.na(primary_sequence_status) &
        reported_primary_moult_status != primary_sequence_status,
      primary_moult_status = coalesce(primary_sequence_status, reported_primary_moult_status),
      status_consistency_note = if_else(
        primary_status_inconsistent,
        paste0(
          "primary_moult_status_raw=",
          primary_moult_status_raw,
          " (",
          reported_primary_moult_status,
          "); derived_from_primary_scores=",
          primary_sequence_status
        ),
        NA_character_
      )
    )

  secondary_note_conflict <- rep(FALSE, nrow(parsed))
  for (field in paste0("S", seq_len(6))) {
    note_field <- paste0("note_", field)
    has_existing <- !is.na(parsed[[field]])
    has_note <- !is.na(parsed[[note_field]])
    fill_idx <- !has_existing & has_note
    conflict_idx <- has_existing & has_note & parsed[[field]] != parsed[[note_field]]

    parsed[[field]][fill_idx] <- parsed[[note_field]][fill_idx]
    secondary_note_conflict <- secondary_note_conflict | conflict_idx
  }

  tertial_note_conflict <- rep(FALSE, nrow(parsed))
  for (field in paste0("T", seq_len(3))) {
    note_field <- paste0("note_", field)
    has_existing <- !is.na(parsed[[field]])
    has_note <- !is.na(parsed[[note_field]])
    fill_idx <- !has_existing & has_note
    conflict_idx <- has_existing & has_note & parsed[[field]] != parsed[[note_field]]

    parsed[[field]][fill_idx] <- parsed[[note_field]][fill_idx]
    tertial_note_conflict <- tertial_note_conflict | conflict_idx
  }

  note <- parsed$status_note |>
    append_note_column(parsed$status_consistency_note) |>
    append_note_column(parsed$old_primaries_note) |>
    append_note_column(parsed$primary_note) |>
    append_note_column(parsed$secondary_note) |>
    append_note_column(parsed$tertial_note) |>
    append_note_column(parsed$tail_note) |>
    append_note_column(parsed$body_note) |>
    append_note_column(if_else(secondary_note_conflict, paste0("moult_note_secondary=", parsed$moult_note_raw), NA_character_)) |>
    append_note_column(if_else(tertial_note_conflict, paste0("moult_note_tertial=", parsed$moult_note_raw), NA_character_)) |>
    append_note_column(parsed$moult_note_remainder)

  parsed |>
    transmute(
      source_file,
      source_sheet,
      source_row,
      ringNumber,
      parsed_date,
      datetime,
      datetime_precision,
      ring_event_id,
      note,
      primary_moult_status,
      n_old_primaries_remaining,
      body_moult_head,
      body_moult_upperparts,
      body_moult_underparts,
      across(all_of(paste0("P", seq_len(10)))),
      across(all_of(paste0("S", seq_len(6)))),
      across(all_of(paste0("T", seq_len(3)))),
      across(all_of(paste0("Tail", seq_len(6)))),
      status_invalid,
      old_primaries_invalid,
      primary_invalid,
      secondary_invalid,
      tertial_invalid,
      tail_invalid,
      body_invalid,
      moult_note_invalid,
      primary_status_inconsistent,
      secondary_note_conflict,
      tertial_note_conflict,
      status_issue_note = status_note,
      old_primaries_issue_note = old_primaries_note,
      primary_issue_note = primary_note,
      secondary_issue_note = secondary_note,
      tertial_issue_note = tertial_note,
      tail_issue_note = tail_note,
      body_issue_note = body_note,
      moult_note_issue_note = if_else(moult_note_invalid, paste0("moult_note_raw=", moult_note_raw), NA_character_),
      status_consistency_issue_note = status_consistency_note,
      moult_invalid = status_invalid | old_primaries_invalid | primary_invalid |
        secondary_invalid | tertial_invalid | tail_invalid | body_invalid |
        moult_note_invalid | primary_status_inconsistent |
        secondary_note_conflict | tertial_note_conflict
    )
}

merge_event_moult_rows <- function(data) {
  primary_fields <- paste0("P", seq_len(10))
  character_moult_fields <- c(
    "primary_moult_status",
    primary_fields,
    paste0("S", seq_len(6)),
    paste0("T", seq_len(3)),
    paste0("Tail", seq_len(6))
  )
  moult_fields <- c(
    "primary_moult_status",
    "n_old_primaries_remaining",
    "body_moult_head",
    "body_moult_upperparts",
    "body_moult_underparts",
    primary_fields,
    paste0("S", seq_len(6)),
    paste0("T", seq_len(3)),
    paste0("Tail", seq_len(6))
  )

  group_sizes <- data |>
    count(ring_event_id, name = "n_group")

  data <- data |>
    left_join(group_sizes, by = "ring_event_id")

  singles <- data |>
    filter(n_group == 1) |>
    transmute(
      ring_event_id,
      note,
      across(all_of(moult_fields)),
      moult_invalid
    )

  duplicates <- data |>
    filter(n_group > 1) |>
    group_by(ring_event_id) |>
    group_modify(\(.x, .y) {
      merged <- tibble()
      conflict_notes <- character()

      for (field in moult_fields) {
        values <- unique(na.omit(.x[[field]]))
        if (length(values) == 1) {
          merged[[field]] <- values[1]
        } else if (length(values) == 0) {
          merged[[field]] <- if (field %in% character_moult_fields) NA_character_ else NA_integer_
        } else {
          merged[[field]] <- if (field %in% character_moult_fields) NA_character_ else NA_integer_
          conflict_notes <- c(
            conflict_notes,
            paste0(
              "conflict_",
              field,
              "=",
              paste(values, collapse = "|")
            )
          )
        }
      }

      row_notes <- .x |>
        mutate(
          note_tag = if_else(
            !is.na(note),
            paste0(source_file, "[", source_row, "]: ", note),
            NA_character_
          )
        ) |>
        pull(note_tag)

      merged$note <- join_note_parts(c(row_notes, conflict_notes))
      merged$moult_invalid <- any(.x$moult_invalid, na.rm = TRUE) |
        length(conflict_notes) > 0
      merged
    }) |>
    ungroup()

  bind_rows(singles, duplicates)
}

build_moult_component_issue <- function(parsed, invalid_col, note_col, issue_type, field, detail) {
  parsed |>
    filter(.data[[invalid_col]]) |>
    transmute(
      source_file,
      source_sheet,
      source_row,
      datetime = case_when(
        datetime_precision == "date" ~ format(parsed_date, "%Y-%m-%d"),
        TRUE ~ format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      ),
      ringNumber,
      issue_type = issue_type,
      field = field,
      value = coalesce(.data[[note_col]], "invalid_moult"),
      detail = detail,
      action = "replace_field_missing",
      action_detail = paste0(
        "Unresolved ", field,
        " values are left missing; other decoded moult values are retained and the original notation is preserved in moult_note."
      )
    )
}

build_moult_output <- function(raw_data, merged_data, same_day_groups) {
  event_lookup <- merged_data |>
    filter(clean_required) |>
    select(row_id, source_file, source_sheet, source_row, ring_event_id)

  observations <- raw_data |>
    resolve_event_row_id(same_day_groups) |>
    filter(clean_required) |>
    left_join(
      event_lookup |>
        select(row_id, ring_event_id),
      by = c("event_row_id" = "row_id")
    ) |>
    mutate(
      has_moult_input = if_any(
        c(
          primary_moult_status_raw,
          old_primaries_raw,
          primary_scores_raw,
          secondary_scores_raw,
          tertial_scores_raw,
          tail_scores_raw,
          body_scores_raw,
          moult_note_raw
        ),
        ~ !is.na(blank_to_na(.x))
      )
    ) |>
    filter(has_moult_input, !is.na(ring_event_id))

  cli::cli_alert_info(
    "Moult: {nrow(observations)} source rows with data across {n_distinct(observations$ring_event_id)} events"
  )

  if (nrow(observations) == 0) {
    return(list(
      moult = tibble(
        ring_event_id = character(),
        moult_note = character(),
        primary_moult_status = character(),
        n_old_primaries_remaining = integer(),
        body_moult_head = integer(),
        body_moult_upperparts = integer(),
        body_moult_underparts = integer(),
        P1 = character(),
        P2 = character(),
        P3 = character(),
        P4 = character(),
        P5 = character(),
        P6 = character(),
        P7 = character(),
        P8 = character(),
        P9 = character(),
        P10 = character(),
        S1 = character(),
        S2 = character(),
        S3 = character(),
        S4 = character(),
        S5 = character(),
        S6 = character(),
        T1 = character(),
        T2 = character(),
        T3 = character(),
        Tail1 = character(),
        Tail2 = character(),
        Tail3 = character(),
        Tail4 = character(),
        Tail5 = character(),
        Tail6 = character()
      ),
      issues = tibble(),
      audit = tibble()
    ))
  }

  parsed <- parse_moult_observations(observations) |>
    mutate(
      decoded_any = if_any(
        c(
          primary_moult_status,
          n_old_primaries_remaining,
          body_moult_head,
          body_moult_upperparts,
          body_moult_underparts,
          paste0("P", seq_len(10)),
          paste0("S", seq_len(6)),
          paste0("T", seq_len(3)),
          paste0("Tail", seq_len(6))
        ),
        ~ !is.na(.x)
      )
    )

  cli::cli_alert_info(
    "Moult: parsed {nrow(parsed)} rows; merging duplicated event records"
  )

  merged <- merge_event_moult_rows(parsed) |>
    filter(
      if_any(
        c(
          primary_moult_status,
          n_old_primaries_remaining,
          body_moult_head,
          body_moult_upperparts,
          body_moult_underparts,
          paste0("P", seq_len(10)),
          paste0("S", seq_len(6)),
          paste0("T", seq_len(3)),
          paste0("Tail", seq_len(6)),
          note
        ),
        ~ !is.na(.x)
      )
    ) |>
    select(-moult_invalid) |>
    rename(moult_note = note)

  cli::cli_alert_success(
    "Moult: exported {nrow(merged)} event rows"
  )

  issues <- bind_rows(
    parsed |>
      filter(status_invalid) |>
      transmute(
        source_file,
        source_sheet,
        source_row,
        datetime = case_when(
          datetime_precision == "date" ~ format(parsed_date, "%Y-%m-%d"),
          TRUE ~ format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        ),
        ringNumber,
        issue_type = "moult_status_invalid",
        field = "primary_moult_status",
        value = status_issue_note,
        detail = "Overall primary-moult status is not one of the documented Ngulia codes 0, 1, 2, or 5 for this source.",
        action = if_else(
          !is.na(primary_moult_status),
          "replace_status_from_sequence",
          "replace_field_missing"
        ),
        action_detail = if_else(
          !is.na(primary_moult_status),
          "The unsupported overall code is retained in moult_note and primary_moult_status is derived from the complete per-feather sequence.",
          "The unresolved overall status is left missing and the original code is retained in moult_note."
        )
      ),
    build_moult_component_issue(
      parsed,
      "old_primaries_invalid",
      "old_primaries_issue_note",
      "moult_old_primaries_invalid",
      "n_old_primaries_remaining",
      "Number of old primaries is not an integer from 0 to 10."
    ),
    build_moult_component_issue(
      parsed,
      "primary_invalid",
      "primary_issue_note",
      "moult_primary_invalid",
      "primary_scores",
      "Primary sequence has an unsupported length or contains unresolved feather codes."
    ),
    build_moult_component_issue(
      parsed,
      "secondary_invalid",
      "secondary_issue_note",
      "moult_secondary_invalid",
      "secondary_scores",
      "Secondary sequence has an unsupported length or contains unresolved feather codes."
    ),
    build_moult_component_issue(
      parsed,
      "tertial_invalid",
      "tertial_issue_note",
      "moult_tertial_invalid",
      "tertial_scores",
      "Tertial sequence has an unsupported length or contains unresolved feather codes."
    ),
    build_moult_component_issue(
      parsed,
      "tail_invalid",
      "tail_issue_note",
      "moult_tail_invalid",
      "tail_scores",
      "Tail sequence has an unsupported length or contains unresolved feather codes."
    ),
    build_moult_component_issue(
      parsed,
      "body_invalid",
      "body_issue_note",
      "moult_body_invalid",
      "body_moult",
      "Body-moult sequence is not three intensity scores from 0 to 3."
    ),
    build_moult_component_issue(
      parsed,
      "moult_note_invalid",
      "moult_note_issue_note",
      "moult_note_unresolved",
      "moult_note",
      "A structured moult value in the note uses a code unsupported by the configured source scheme."
    ),
    parsed |>
      filter(primary_status_inconsistent) |>
      transmute(
        source_file,
        source_sheet,
        source_row,
        datetime = case_when(
          datetime_precision == "date" ~ format(parsed_date, "%Y-%m-%d"),
          TRUE ~ format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        ),
        ringNumber,
        issue_type = "moult_status_inconsistent",
        field = "primary_moult_status",
        value = status_consistency_issue_note,
        detail = "Reported overall status conflicts with the status derived from a complete 0-5 primary-feather sequence.",
        action = "replace_status_from_sequence",
        action_detail = "The complete per-feather sequence is used for primary_moult_status; both interpretations are preserved in moult_note."
      ),
    parsed |>
      filter(secondary_note_conflict | tertial_note_conflict) |>
      transmute(
        source_file,
        source_sheet,
        source_row,
        datetime = case_when(
          datetime_precision == "date" ~ format(parsed_date, "%Y-%m-%d"),
          TRUE ~ format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        ),
        ringNumber,
        issue_type = "moult_note_conflict",
        field = if_else(secondary_note_conflict, "secondary_scores", "tertial_scores"),
        value = coalesce(note, "moult_note_conflict"),
        detail = "Structured moult note conflicts with a dedicated feather-score field.",
        action = "replace_field_missing",
        action_detail = "Conflicting decoded values are left missing and both source notations are preserved in moult_note."
      )
  ) |>
    arrange(source_file, source_sheet, source_row, issue_type)

  audit <- parsed |>
    group_by(source_file, source_sheet) |>
    summarise(
      n_rows_with_moult_data = n(),
      n_rows_decoded_moult = sum(decoded_any, na.rm = TRUE),
      n_rows_invalid_moult = sum(moult_invalid, na.rm = TRUE),
      .groups = "drop"
    )

  list(moult = merged, issues = issues, audit = audit)
}
