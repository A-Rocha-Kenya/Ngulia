library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

curated_dir <- paths$curated_dir
daily_counts_dir <- paths$daily_counts_intermediate_dir
weather_dir <- paths$weather_intermediate_dir

daily_counts_path <- file.path(curated_dir, "daily_counts.csv")
djp_daily_counts_path <- file.path(daily_counts_dir, "djp_daily_counts.csv")
djp_metadata_path <- file.path(daily_counts_dir, "djp_daily_metadata.csv")
era5_daily_weather_path <- file.path(weather_dir, "era5_daily_weather.csv")
daily_coverage_output_path <- file.path(curated_dir, "daily_coverage.csv")

dir.create(curated_dir, recursive = TRUE, showWarnings = FALSE)

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

build_season_dates <- function(..., seasons = 1969:2023) {
  season_bounds <- bind_rows(...) |>
    filter(!is.na(date), !is.na(season)) |>
    distinct(season, date) |>
    group_by(season) |>
    summarise(
      max_date = max(date),
      .groups = "drop"
    )

  default_bounds <- tibble(season = as.integer(seasons)) |>
    mutate(
      default_min_date = make_date(season, 10L, 20L),
      default_max_date = make_date(season + 1L, 1L, 12L)
    ) |>
    left_join(season_bounds, by = "season") |>
    mutate(
      min_date = default_min_date,
      max_date = case_when(
        !is.na(max_date) & month(max_date) <= 1L ~ pmax(default_max_date, max_date),
        TRUE ~ default_max_date
      )
    ) |>
    arrange(season)

  bind_rows(lapply(seq_len(nrow(default_bounds)), function(i) {
    tibble(
      date = seq(default_bounds$min_date[[i]], default_bounds$max_date[[i]], by = "1 day"),
      season = default_bounds$season[[i]]
    )
  }))
}

decode_djp_weather <- function(weather_code) {
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

cli_h1("Build daily coverage")

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

daily_ring_totals <- daily_counts |>
  group_by(date) |>
  summarise(total_birds_ringed = sum(n_records, na.rm = TRUE), .groups = "drop")

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
    djp_pax
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
    total_birds_ringed = coalesce(total_birds_ringed, 0L),
    djp_total_birds_ringed = coalesce(djp_total_birds_ringed, 0L),
    has_djp_metadata = coalesce(has_djp_metadata, FALSE),
    has_era5_weather = coalesce(has_era5_weather, FALSE),
    has_djp_daily_counts = djp_total_birds_ringed > 0L,
    ringing_happened = total_birds_ringed > 0L
  ) |>
  select(
    date,
    season,
    total_birds_ringed,
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
    total_cloud_cover_mean,
    cloud_base_height_mean_m,
    total_precipitation_00_08_mm,
    wind_u_10m_mean_ms,
    wind_v_10m_mean_ms,
    wind_speed_10m_mean_ms,
    temperature_2m_mean_c,
    relative_humidity_mean_pct,
    surface_pressure_mean_hpa,
    mist_score_era5
  ) |>
  rename(ringing_date = date)

# Write output ------------------------------------------------------------

write_csv(daily_coverage, daily_coverage_output_path, na = "")

cli_alert_success(
  "Wrote {nrow(daily_coverage)} daily coverage rows to {daily_coverage_output_path}"
)
