library(dplyr)
library(readr)
library(tidyr)
library(lubridate)
library(stringr)
library(cli)
library(ecmwfr)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)
source(file.path(project_dir, "scripts", "helpers", "season_calendar.R"))

curated_dir <- paths$curated_dir
daily_counts_dir <- paths$daily_counts_intermediate_dir
weather_dir <- paths$weather_intermediate_dir
era5_dir <- file.path(paths$weather_raw_dir, "era5_hourly_single_levels_timeseries")

dir.create(curated_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(weather_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(era5_dir, recursive = TRUE, showWarnings = FALSE)

weather_output_path <- file.path(weather_dir, "era5_daily_weather.csv")
daily_counts_path <- file.path(curated_dir, "daily_counts.csv")
djp_daily_counts_path <- file.path(daily_counts_dir, "djp_daily_counts.csv")
djp_metadata_path <- file.path(daily_counts_dir, "djp_daily_metadata.csv")

source(file.path(project_dir, "scripts", "helpers", "ring_event_utils.R"))

# Set request parameters --------------------------------------------------

latitude <- -3.014228557724911
longitude <- 38.21086746779849
local_timezone <- "Africa/Nairobi"
request_latitude <- round(latitude * 4) / 4
request_longitude <- round(longitude * 4) / 4

# The CDS point time-series dataset does not provide low cloud cover.
# Use total cloud cover and cloud base height instead for the cloud/fog proxy.
era5_variables <- c(
  "total_cloud_cover",
  "cloud_base_height",
  "total_precipitation",
  "10m_u_component_of_wind",
  "10m_v_component_of_wind",
  "2m_temperature",
  "2m_dewpoint_temperature",
  "surface_pressure"
)

normalize_name <- function(x) {
  tolower(gsub("[^a-z0-9]+", "", x))
}

find_column_name <- function(data, aliases) {
  data_names <- names(data)
  normalized_names <- normalize_name(data_names)
  alias_names <- normalize_name(aliases)

  exact_match <- which(normalized_names %in% alias_names)
  if (length(exact_match) > 0) {
    return(data_names[exact_match[1]])
  }

  contains_match <- which(vapply(
    normalized_names,
    \(name) any(grepl(paste(alias_names, collapse = "|"), name)),
    logical(1)
  ))

  if (length(contains_match) > 0) {
    return(data_names[contains_match[1]])
  }

  NA_character_
}

compute_relative_humidity <- function(temperature_c, dewpoint_c) {
  vapor_pressure <- 6.112 * exp((17.67 * dewpoint_c) / (dewpoint_c + 243.5))
  saturation_vapor_pressure <- 6.112 *
    exp((17.67 * temperature_c) / (temperature_c + 243.5))
  pmin(pmax(100 * vapor_pressure / saturation_vapor_pressure, 0), 100)
}

read_era5_timeseries_csv <- function(csv_path) {
  hourly_raw <- read_csv(
    csv_path,
    show_col_types = FALSE,
    col_types = cols(.default = col_character())
  )

  time_col <- find_column_name(hourly_raw, c("time", "datetime", "valid_time"))
  latitude_col <- find_column_name(hourly_raw, "latitude")
  longitude_col <- find_column_name(hourly_raw, "longitude")
  total_cloud_cover_col <- find_column_name(hourly_raw, c("total_cloud_cover", "tcc"))
  cloud_base_height_col <- find_column_name(hourly_raw, c("cloud_base_height", "cbh"))
  total_precipitation_col <- find_column_name(hourly_raw, c("total_precipitation", "tp"))
  wind_u_col <- find_column_name(hourly_raw, c("10m_u_component_of_wind", "u10"))
  wind_v_col <- find_column_name(hourly_raw, c("10m_v_component_of_wind", "v10"))
  temperature_col <- find_column_name(hourly_raw, c("2m_temperature", "t2m"))
  dewpoint_col <- find_column_name(hourly_raw, c("2m_dewpoint_temperature", "d2m"))
  surface_pressure_col <- find_column_name(hourly_raw, c("surface_pressure", "sp"))

  required_columns <- c(
    time_col,
    total_cloud_cover_col,
    cloud_base_height_col,
    total_precipitation_col,
    wind_u_col,
    wind_v_col,
    temperature_col,
    dewpoint_col,
    surface_pressure_col
  )

  if (any(is.na(required_columns))) {
    cli_abort(
      c(
        "Missing expected columns in ERA5 time-series CSV.",
        "x" = paste(names(hourly_raw), collapse = ", ")
      )
    )
  }

  hourly_raw |>
    transmute(
      datetime_utc = parse_date_time(
        .data[[time_col]],
        orders = c("Ymd HMS", "Ymd HM", "Y-m-d H:M:S", "Y-m-d H:M"),
        tz = "UTC"
      ),
      latitude = if (!is.na(latitude_col)) as.numeric(.data[[latitude_col]]) else request_latitude,
      longitude = if (!is.na(longitude_col)) as.numeric(.data[[longitude_col]]) else request_longitude,
      total_cloud_cover = as.numeric(.data[[total_cloud_cover_col]]),
      cloud_base_height_m = as.numeric(.data[[cloud_base_height_col]]),
      total_precipitation = as.numeric(.data[[total_precipitation_col]]),
      wind_u_10m = as.numeric(.data[[wind_u_col]]),
      wind_v_10m = as.numeric(.data[[wind_v_col]]),
      temperature_2m = as.numeric(.data[[temperature_col]]),
      dewpoint_2m = as.numeric(.data[[dewpoint_col]]),
      surface_pressure = as.numeric(.data[[surface_pressure_col]])
    ) |>
    filter(!is.na(datetime_utc))
}

resolve_era5_timeseries_path <- function(csv_path) {
  if (file.exists(csv_path)) {
    return(csv_path)
  }

  zip_path <- str_replace(csv_path, "\\.csv$", ".zip")

  if (!file.exists(zip_path)) {
    cli_abort("ERA5 time-series download did not produce {csv_path} or {zip_path}")
  }

  zip_listing <- unzip(zip_path, list = TRUE)
  csv_members <- zip_listing$Name[str_detect(zip_listing$Name, "\\.csv$")]

  if (length(csv_members) == 0) {
    cli_abort("ERA5 archive does not contain a CSV: {zip_path}")
  }

  extracted_csv <- file.path(dirname(zip_path), basename(csv_members[1]))

  if (!file.exists(extracted_csv)) {
    unzip(zip_path, files = csv_members[1], exdir = dirname(zip_path))
  }

  extracted_csv
}

make_era5_request <- function(start_date, end_date, target_name) {
  list(
    dataset_short_name = "reanalysis-era5-single-levels-timeseries",
    variable = era5_variables,
    location = list(
      latitude = request_latitude,
      longitude = request_longitude
    ),
    date = I(list(sprintf("%s/%s", start_date, end_date))),
    data_format = "csv",
    target = target_name
  )
}

# Build request window ----------------------------------------------------

daily_counts_dates <- read_csv(
  daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(
    ringing_date = col_date(),
    season = col_integer()
  )
) |>
  rename(date = ringing_date) |>
  select(date, season)

djp_daily_counts_dates <- read_csv(
  djp_daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(date = col_date())
) |>
  transmute(date, season = assign_season_from_date(date))

djp_daily_metadata_dates <- read_csv(
  djp_metadata_path,
  show_col_types = FALSE,
  col_types = cols(date = col_date())
) |>
  transmute(date, season = assign_season_from_date(date))

date_grid <- build_season_dates(
  daily_counts_dates,
  djp_daily_counts_dates,
  djp_daily_metadata_dates
) |>
  mutate(
    year = year(date),
    yday = yday(date),
    latitude = request_latitude,
    longitude = request_longitude
  )

request_start_date <- min(date_grid$date)
request_end_date <- max(date_grid$date)
timeseries_filename <- sprintf(
  "era5_hourly_single_levels_timeseries_%s_%s.csv",
  format(request_start_date, "%Y%m%d"),
  format(request_end_date, "%Y%m%d")
)
timeseries_path <- file.path(era5_dir, timeseries_filename)
timeseries_zip_path <- str_replace(timeseries_path, "\\.csv$", ".zip")

# Download ERA5 file ------------------------------------------------------

cli_h1("Download ERA5 hourly single-level weather")
cli_alert_info(
  "Using {nrow(date_grid)} daily count dates from {min(date_grid$date)} to {max(date_grid$date)}"
)
cli_alert_info(
  "Requesting ERA5 at snapped grid point {request_latitude}, {request_longitude}"
)
cli_alert_info(
  "Requesting one ERA5 point time series from {request_start_date} to {request_end_date}"
)

request <- make_era5_request(
  request_start_date,
  request_end_date,
  timeseries_filename
)

if (file.exists(timeseries_path)) {
  cli_alert_info("Using existing ERA5 time-series file: {timeseries_path}")
} else if (file.exists(timeseries_zip_path)) {
  cli_alert_info("Using existing ERA5 time-series archive: {timeseries_zip_path}")
} else {
  wf_request(
    request = request,
    transfer = TRUE,
    path = era5_dir,
    time_out = 21600,
    retry = 60
  )
}

timeseries_input_path <- resolve_era5_timeseries_path(timeseries_path)

# Read hourly weather -----------------------------------------------------

hourly_weather <- read_era5_timeseries_csv(timeseries_input_path) |>
  mutate(
    datetime_local = with_tz(datetime_utc, local_timezone),
    date = as.Date(datetime_local),
    hour = hour(datetime_local),
    total_precipitation_mm = total_precipitation * 1000,
    wind_u_10m_ms = wind_u_10m,
    wind_v_10m_ms = wind_v_10m,
    wind_speed_10m_ms = sqrt(wind_u_10m_ms^2 + wind_v_10m_ms^2),
    temperature_2m_c = temperature_2m - 273.15,
    dewpoint_2m_c = dewpoint_2m - 273.15,
    dewpoint_depression_c = temperature_2m_c - dewpoint_2m_c,
    surface_pressure_hpa = surface_pressure / 100,
    relative_humidity_pct = compute_relative_humidity(
      temperature_2m_c,
      dewpoint_2m_c
    )
  ) |>
  filter(
    date %in% date_grid$date,
    hour >= 0,
    hour <= 8
  )

# Summarize daily weather -------------------------------------------------

daily_weather <- hourly_weather |>
  group_by(date) |>
  summarise(
    n_hours = n_distinct(datetime_local),
    total_cloud_cover_mean = mean(total_cloud_cover, na.rm = TRUE),
    cloud_base_height_mean_m = mean(cloud_base_height_m, na.rm = TRUE),
    cloud_base_height_min_m = if (all(is.na(cloud_base_height_m))) NA_real_ else min(cloud_base_height_m, na.rm = TRUE),
    total_precipitation_00_08_mm = sum(total_precipitation_mm, na.rm = TRUE),
    wind_u_10m_mean_ms = mean(wind_u_10m_ms, na.rm = TRUE),
    wind_v_10m_mean_ms = mean(wind_v_10m_ms, na.rm = TRUE),
    wind_speed_10m_mean_ms = mean(wind_speed_10m_ms, na.rm = TRUE),
    temperature_2m_mean_c = mean(temperature_2m_c, na.rm = TRUE),
    dewpoint_2m_mean_c = mean(dewpoint_2m_c, na.rm = TRUE),
    dewpoint_depression_min_c = min(dewpoint_depression_c, na.rm = TRUE),
    relative_humidity_mean_pct = mean(relative_humidity_pct, na.rm = TRUE),
    relative_humidity_max_pct = max(relative_humidity_pct, na.rm = TRUE),
    near_saturated_hours = sum(relative_humidity_pct >= 95, na.rm = TRUE),
    surface_pressure_mean_hpa = mean(surface_pressure_hpa, na.rm = TRUE),
    .groups = "drop"
  )

weather_output <- date_grid |>
  left_join(daily_weather, by = "date") |>
  select(
    date,
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
  )

# Write output ------------------------------------------------------------

write_csv(weather_output, weather_output_path, na = "")

cli_alert_success(
  "Wrote {nrow(weather_output)} daily weather rows to {weather_output_path}"
)
