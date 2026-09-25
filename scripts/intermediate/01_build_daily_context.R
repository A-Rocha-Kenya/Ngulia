library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)
source(file.path(project_dir, "scripts", "helpers", "season_calendar.R"))

curated_dir <- paths$curated_dir
daily_counts_dir <- paths$daily_counts_intermediate_dir
weather_dir <- paths$weather_intermediate_dir

daily_counts_path <- file.path(curated_dir, "daily_counts.csv")
djp_daily_counts_path <- file.path(daily_counts_dir, "djp_daily_counts.csv")
djp_metadata_path <- file.path(daily_counts_dir, "djp_daily_metadata.csv")
era5_daily_weather_path <- file.path(weather_dir, "era5_daily_weather.csv")
daily_context_dir <- paths$daily_context_intermediate_dir
daily_coverage_output_path <- file.path(daily_context_dir, "daily_context.csv")

dir.create(daily_context_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path(project_dir, "scripts", "helpers", "ring_event_helpers.R"))

# Moon phase --------------------------------------------------------------

synodic_month_days <- 29.530588853
reference_new_moon <- ymd_hms("2000-01-06 18:14:00", tz = "UTC")

collapse_labels <- function(labels) {
  labels <- labels[!is.na(labels) & labels != ""]

  if (length(labels) == 0) {
    return(NA_character_)
  }

  paste(labels, collapse = ",")
}

compute_moon_metrics <- function(date) {
  datetime_utc <- as_datetime(date, tz = "UTC") + hours(12)
  moon_age_days <- as.numeric(difftime(datetime_utc, reference_new_moon, units = "days")) %%
    synodic_month_days
  moon_days_from_new_moon <- if_else(
    moon_age_days <= synodic_month_days / 2,
    moon_age_days,
    moon_age_days - synodic_month_days
  )
  moon_illumination_fraction <- 0.5 *
    (1 - cos(2 * pi * moon_age_days / synodic_month_days))

  tibble(
    date = as.Date(date),
    moon_age_days = round(moon_age_days, 2),
    moon_days_from_new_moon = as.integer(round(moon_days_from_new_moon)),
    moon_illumination_fraction = round(moon_illumination_fraction, 3),
    moon_phase_name = case_when(
      moon_age_days < 1.84566 ~ "new_moon",
      moon_age_days < 5.53699 ~ "waxing_crescent",
      moon_age_days < 9.22831 ~ "first_quarter",
      moon_age_days < 12.91963 ~ "waxing_gibbous",
      moon_age_days < 16.61096 ~ "full_moon",
      moon_age_days < 20.30228 ~ "waning_gibbous",
      moon_age_days < 23.99361 ~ "last_quarter",
      moon_age_days < 27.68493 ~ "waning_crescent",
      TRUE ~ "new_moon"
    )
  )
}

decode_djp_weather <- function(weather_code) {
  # Combined codes retain the case-sensitive mist code; suffix R/r is rain.
  weather_code <- str_remove(weather_code, "(?<=[Mmlco])[Rr]$")
  case_when(
    weather_code == "M" ~ "good_mist_2h_plus",
    weather_code == "m" ~ "light_or_patchy_mist_1h_plus",
    weather_code == "MR" ~ "good_mist_2h_plus",
    weather_code == "l" ~ "low_cloud",
    weather_code == "c" ~ "high_cloud",
    weather_code == "o" ~ "clear",
    is.na(weather_code) | weather_code %in% c("?", "X") ~ "unknown",
    TRUE ~ weather_code
  )
}

decode_djp_rain <- function(weather_code, rain_code) {
  rain_code <- coalesce(rain_code, str_extract(weather_code, "(?<=[Mmlco])[Rr]$"))
  case_when(
    rain_code == "R" ~ "heavy_rain_1h_plus",
    rain_code == "r" ~ "light_or_heavy_showers",
    weather_code == "MR" ~ "rain_noted_in_weather_code",
    is.na(rain_code) ~ "none",
    TRUE ~ rain_code
  )
}

decode_djp_site <- function(site_code) {
  vapply(site_code, function(code) {
    if (is.na(code) || code == "?") {
      return("unknown")
    }

    if (code == "O") {
      return("none")
    }

    collapse_labels(c(
      if (str_detect(code, "B")) "back_bush",
      if (str_detect(code, "F")) "front_bush",
      if (str_detect(code, "N")) "outside_night_nets",
      if (str_detect(code, "L")) "lodge_veranda",
      if (str_detect(code, "S")) "swallow_nets"
    ))
  }, character(1))
}

decode_djp_tape <- function(tape_code) {
  vapply(tape_code, function(code) {
    if (is.na(code) || code == "") {
      return("none")
    }

    collapse_labels(c(
      if (str_detect(code, "T")) "front_tapes",
      if (str_detect(code, "t")) "behind_lodge_tapes"
    ))
  }, character(1))
}

decode_djp_pax <- function(pax_code) {
  vapply(pax_code, function(code) {
    if (is.na(code) || code == "?" || code == "") {
      return("unknown")
    }

    str_replace_all(code, "\\+", "_plus_")
  }, character(1))
}

# Read data ---------------------------------------------------------------

cli_h1("Build intermediate daily context")

if (!file.exists(era5_daily_weather_path)) {
  cli_abort(
    "Missing staged ERA5 daily weather file: {era5_daily_weather_path}. Run `scripts/curated/04_build_era5_daily_weather.R` first."
  )
}

daily_counts <- read_csv(
  daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(
    ringing_date = col_date(),
    season = col_integer(),
    n_records = col_integer(),
    .default = col_character()
  )
) |>
  rename(date = ringing_date)

djp_daily_counts <- read_csv(
  djp_daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(
    date = col_date(),
    afring_number = col_character(),
    n_records = col_integer()
  )
) |>
  mutate(season = assign_season_from_date(date))

djp_daily_metadata <- read_csv(
  djp_metadata_path,
  show_col_types = FALSE,
  col_types = cols(
    year = col_integer(),
    month = col_integer(),
    day = col_integer(),
    date = col_date(),
    moon = col_integer(),
    weather = col_character(),
    rain = col_character(),
    site = col_character(),
    tape = col_character(),
    pax = col_character()
  )
)

era5_daily_weather <- read_csv(
  era5_daily_weather_path,
  show_col_types = FALSE,
  col_types = cols(date = col_date())
)

# Compute derived tables --------------------------------------------------

excluded_capture_groups <- read_csv(
  file.path(project_dir, "config", "analysis", "excluded_capture_groups.csv"),
  show_col_types = FALSE
)

daily_ring_totals <- daily_counts |>
  group_by(date) |>
  summarise(
    all_birds_ringed = sum(n_records, na.rm = TRUE),
    swallow_birds_ringed = sum(n_records[avibase_id %in% excluded_capture_groups$avibase_id], na.rm = TRUE),
    total_birds_ringed = all_birds_ringed - swallow_birds_ringed,
    .groups = "drop"
  )

djp_daily_totals <- djp_daily_counts |>
  group_by(date) |>
  summarise(djp_total_birds_ringed = sum(n_records, na.rm = TRUE), .groups = "drop")

djp_daily_metadata_clean <- djp_daily_metadata |>
  mutate(
    has_djp_metadata = TRUE,
    djp_moon_days_from_new_moon = moon,
    weather_code = na_if(weather, ""),
    rain_code = na_if(rain, ""),
    site_code = na_if(str_to_upper(site), ""),
    tape_code = na_if(tape, ""),
    pax_code = na_if(pax, ""),
    djp_weather = decode_djp_weather(weather_code),
    djp_rain = decode_djp_rain(weather_code, rain_code),
    djp_site = decode_djp_site(site_code),
    djp_tape = decode_djp_tape(tape_code),
    djp_pax = decode_djp_pax(pax_code)
  ) |>
  select(
    date,
    has_djp_metadata,
    djp_moon_days_from_new_moon,
    djp_weather,
    djp_rain,
    djp_site,
    djp_tape,
    djp_pax,
    djp_source_row = source_row, djp_reported_total = reported_total
  )

era5_daily_weather_clean <- era5_daily_weather |>
  mutate(has_era5_weather = TRUE)

date_index <- build_season_dates(
  daily_counts |> select(date, season),
  djp_daily_counts |> select(date, season),
  djp_daily_metadata |>
    transmute(date, season = assign_season_from_date(date))
)

moon_metrics <- compute_moon_metrics(date_index$date)

daily_coverage <- date_index |>
  left_join(daily_ring_totals, by = "date") |>
  left_join(djp_daily_totals, by = "date") |>
  left_join(moon_metrics, by = "date") |>
  left_join(djp_daily_metadata_clean, by = "date") |>
  left_join(era5_daily_weather_clean, by = "date") |>
  mutate(
    # Retain only source-recorded zeros, not gaps in the species-count table.
    total_birds_ringed = if_else(is.na(total_birds_ringed) & djp_reported_total == 0L, 0L, total_birds_ringed, missing = total_birds_ringed),
    all_birds_ringed = if_else(is.na(all_birds_ringed) & djp_reported_total == 0L, 0L, all_birds_ringed, missing = all_birds_ringed),
    swallow_birds_ringed = coalesce(swallow_birds_ringed, 0L),
    has_djp_metadata = coalesce(has_djp_metadata, FALSE),
    has_era5_weather = coalesce(has_era5_weather, FALSE),
    has_djp_daily_counts = coalesce(djp_total_birds_ringed > 0L, FALSE),
    ringing_happened = coalesce(total_birds_ringed > 0L, FALSE),
    daily_count_status = case_when(
      ringing_happened ~ "positive_count_recorded",
      total_birds_ringed == 0L & all_birds_ringed > 0L ~ "zero_after_swallow_exclusion",
      total_birds_ringed == 0L ~ "zero_in_daily_summary",
      TRUE ~ "missing"
    )
  ) |>
  select(
    date,
    season,
    total_birds_ringed,
    all_birds_ringed,
    swallow_birds_ringed,
    ringing_happened,
    djp_total_birds_ringed,
    djp_moon_days_from_new_moon,
    moon_days_from_new_moon,
    moon_illumination_fraction,
    moon_phase_name,
    djp_weather,
    djp_rain,
    djp_site,
    djp_tape,
    djp_pax,
    djp_source_row,
    djp_reported_total,
    daily_count_status,
    total_cloud_cover_mean,
    cloud_base_height_mean_m,
    cloud_base_height_min_m,
    total_precipitation_00_08_mm,
    wind_u_10m_mean_ms,
    wind_v_10m_mean_ms,
    wind_speed_10m_mean_ms,
    temperature_2m_mean_c,
    dewpoint_2m_mean_c,
    dewpoint_depression_min_c,
    relative_humidity_mean_pct,
    relative_humidity_max_pct,
    near_saturated_hours,
    surface_pressure_mean_hpa
  ) |>
  rename(ringing_date = date)

# Reconcile observed covariates with reviewed source evidence ---------------
# DJP fields remain source-specific; canonical observations can be corrected.
operations_history <- read_csv(file.path(project_dir, "config", "daily_covariates", "operations_history.csv"), show_col_types = FALSE, guess_max = Inf)
daily_coverage <- daily_coverage |>
  mutate(
    mist_observation = case_when(
      djp_weather == "good_mist_2h_plus" ~ "good",
      djp_weather == "light_or_patchy_mist_1h_plus" ~ "light_patchy",
      djp_weather %in% c("low_cloud", "high_cloud", "clear") ~ "none",
      TRUE ~ NA_character_
    ),
    rain_observed = recode(djp_rain, none = "none", light_or_heavy_showers = "showers", heavy_rain_1h_plus = "heavy_rain", rain_noted_in_weather_code = "rain_unspecified"),
    net_sites_observed = na_if(djp_site, "unknown"),
    playback_nocturnal_observed = if_else(is.na(djp_tape), NA_integer_, as.integer(djp_tape != "none")),
    night_net_operation = if_else(is.na(net_sites_observed), NA_integer_, as.integer(str_detect(net_sites_observed, "outside_night_nets"))),
    dawn_net_operation = if_else(is.na(net_sites_observed), NA_integer_, as.integer(str_detect(net_sites_observed, "back_bush|front_bush"))),
    daily_count_source = case_when(
      daily_count_status == "zero_in_daily_summary" ~ paste0("DJP workbook Sheet1!BS", djp_source_row),
      ringing_happened ~ "curated daily_counts.csv",
      TRUE ~ NA_character_
    )
  )
model_daily_fields <- c("mist_observation", "rain_observed", "net_sites_observed",
  "playback_nocturnal_observed", "night_net_operation", "dawn_net_operation")

daily_updates <- operations_history |>
  filter(!is.na(daily_values)) |>
  rowwise() |>
  reframe(evidence_id, source_path, source_page,
    ringing_date = seq(daily_start_date, daily_end_date, by = "day"), daily_values) |>
  tidyr::separate_longer_delim(daily_values, delim = ";") |>
  tidyr::separate_wider_delim(daily_values, delim = "=", names = c("field", "value")) |>
  filter(field %in% model_daily_fields)
# Conflicting source decisions must be resolved in history, not by row order.
stopifnot(all((daily_updates |> group_by(ringing_date, field) |> summarise(n = n_distinct(value), .groups = "drop"))$n == 1L))
daily_updates <- daily_updates |> group_by(ringing_date, field, value) |>
  summarise(source = paste(paste0(evidence_id, ": ", source_path, "; ", source_page), collapse = " | "),
    evidence_id = paste(evidence_id, collapse = ";"), .groups = "drop")
reconciliation <- daily_updates |>
  left_join(daily_coverage |> select(ringing_date, all_of(model_daily_fields)) |>
    mutate(across(all_of(model_daily_fields), as.character)) |>
    tidyr::pivot_longer(-ringing_date, names_to = "field", values_to = "previous_value"), by = c("ringing_date", "field")) |>
  mutate(action = case_when(
    !ringing_date %in% daily_coverage$ringing_date ~ "outside_calendar",
    is.na(previous_value) ~ "filled",
    previous_value == value ~ "validated",
    TRUE ~ "corrected"
  ))
for (field in model_daily_fields) {
  update <- daily_updates |> filter(.data$field == .env$field)
  match_row <- match(daily_coverage$ringing_date, update$ringing_date)
  selected <- !is.na(match_row)
  value <- update$value[match_row[selected]]
  if (is.numeric(daily_coverage[[field]])) value <- as.integer(value)
  daily_coverage[[field]][selected] <- value
}
daily_evidence <- daily_updates |>
  group_by(ringing_date) |>
  summarise(operations_evidence_ids = paste(sort(unique(unlist(str_split(evidence_id, ";")))), collapse = ";"), .groups = "drop")
daily_coverage <- daily_coverage |> left_join(daily_evidence, by = "ringing_date")
reconciliation_dir <- file.path(paths$qa_output_dir, "daily_covariate_reconciliation")
dir.create(reconciliation_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(reconciliation, file.path(reconciliation_dir, "source_decisions.csv"))
write_csv(daily_coverage |> filter(daily_count_status == "zero_in_daily_summary") |>
  select(ringing_date, total_birds_ringed, djp_source_row, djp_reported_total, daily_count_source, djp_site),
  file.path(reconciliation_dir, "source_recorded_zeros.csv"))

# Write output ------------------------------------------------------------

write_csv(daily_coverage, daily_coverage_output_path, na = "")

cli_alert_success(
  "Wrote {nrow(daily_coverage)} intermediate daily-context rows to {daily_coverage_output_path}"
)
