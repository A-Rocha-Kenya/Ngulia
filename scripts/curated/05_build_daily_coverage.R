library(dplyr)
library(readr)
library(lubridate)
library(stringr)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

daily_context_path <- file.path(paths$daily_context_intermediate_dir, "daily_context.csv")
mist_prediction_path <- file.path(paths$mist_intermediate_dir, "mist_state_probabilities.csv")
daily_coverage_path <- file.path(paths$curated_dir, "daily_coverage.csv")

dir.create(paths$curated_dir, recursive = TRUE, showWarnings = FALSE)

# Read intermediate sources ----------------------------------------------

cli_h1("Build curated daily coverage")

daily_context <- read_csv(
  daily_context_path,
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date(),
    playback_nocturnal_observed = col_integer(),
    night_net_operation = col_integer(), dawn_net_operation = col_integer())
)

mist_predictions <- read_csv(
  mist_prediction_path,
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
)

# Consolidate reusable daily fields --------------------------------------

daily_coverage <- daily_context |>
  left_join(mist_predictions, by = c("ringing_date", "season")) |>
  mutate(
    season_day = as.integer(ringing_date - make_date(season, 10L, 20L)) + 1L,
    moon_distance_from_new_moon = abs(moon_days_from_new_moon),
    djp_team_size_base = as.integer(str_extract(djp_pax, "^[0-9]+")),
    djp_earthwatch_participants = as.integer(str_match(djp_pax, "_plus_([0-9]+)EW$")[, 2]),
    djp_team_size_total = case_when(
      str_detect(djp_pax, "^[0-9]+$") ~ djp_team_size_base,
      !is.na(djp_earthwatch_participants) ~ djp_team_size_base + djp_earthwatch_participants,
      TRUE ~ NA_integer_
    ),
    djp_team_size_minimum = djp_team_size_base + coalesce(djp_earthwatch_participants, 0L),
    djp_team_size_interpretation = case_when(
      str_detect(djp_pax, "^[0-9]+$") ~ "exact_total",
      !is.na(djp_earthwatch_participants) ~ "exact_base_plus_earthwatch",
      str_detect(djp_pax, "^[0-9]+_plus_EW$") ~ "minimum_plus_unspecified_earthwatch",
      djp_pax == "unknown" ~ "recorded_unknown",
      TRUE ~ "not_recorded"
    ),
    bush_net_configuration = case_when(
      season < 1977L ~ NA_character_,
      season <= 1993L ~ "back_bush",
      season %in% 1994:1995 ~ "transition",
      TRUE ~ "front_bush"
    ),
    night_net_configuration = if_else(season >= 1977L, "established", NA_character_),
    effort_status = case_when(
      ringing_happened & net_sites_observed == "none" ~ "conflicting_positive_catch_and_no_site",
      night_net_operation == 1L | dawn_net_operation == 1L | (!is.na(net_sites_observed) & net_sites_observed != "none") ~ "documented_operation",
      ringing_happened ~ "inferred_operation_from_positive_catch",
      net_sites_observed == "none" | (night_net_operation == 0L & dawn_net_operation == 0L) ~ "documented_no_operation",
      TRUE ~ "unknown"
    )
  ) |>
  select(
    ringing_date,
    season,
    season_day,
    total_birds_ringed,
    all_birds_ringed,
    swallow_birds_ringed,
    ringing_happened,
    daily_count_status, daily_count_source, djp_reported_total, djp_source_row,
    moon_days_from_new_moon,
    moon_distance_from_new_moon,
    moon_illumination_fraction,
    moon_phase_name,
    djp_weather,
    djp_rain,
    mist_observation,
    mist_probability_none,
    mist_probability_light_patchy,
    mist_probability_good,
    djp_site,
    djp_tape,
    djp_pax,
    djp_team_size_total,
    djp_team_size_minimum,
    djp_team_size_interpretation,
    bush_net_configuration,
    night_net_configuration,
    effort_status,
    total_cloud_cover_mean,
    cloud_base_height_mean_m,
    total_precipitation_00_08_mm,
    wind_u_10m_mean_ms,
    wind_v_10m_mean_ms,
    wind_speed_10m_mean_ms,
    temperature_2m_mean_c,
    relative_humidity_mean_pct,
    surface_pressure_mean_hpa,
    rain_observed,
    net_sites_observed,
    playback_nocturnal_observed,
    night_net_operation,
    dawn_net_operation,
    operations_evidence_ids
  )

# Write output ------------------------------------------------------------

write_csv(daily_coverage, daily_coverage_path, na = "")

cli_alert_success("Wrote {nrow(daily_coverage)} curated rows to {daily_coverage_path}")
