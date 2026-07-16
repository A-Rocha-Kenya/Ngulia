# Return the project data and configuration directories used across scripts.
get_data_paths <- function(project_dir = normalizePath(".", mustWork = TRUE)) {
  data_dir <- file.path(project_dir, "data")
  config_dir <- file.path(project_dir, "config")

  raw_dir <- file.path(data_dir, "01_raw")
  reference_dir <- file.path(data_dir, "02_reference")
  intermediate_dir <- file.path(data_dir, "03_intermediate")
  curated_dir <- file.path(data_dir, "04_curated")
  derived_dir <- file.path(data_dir, "05_derived")

  list(
    reference_dir = reference_dir,
    curated_dir = curated_dir,
    derived_dir = derived_dir,
    external_dir = file.path(raw_dir, "external"),
    ring_events_raw_dir = file.path(raw_dir, "ring_events"),
    daily_counts_raw_dir = file.path(raw_dir, "daily_counts"),
    weather_raw_dir = file.path(raw_dir, "weather"),
    ring_events_config_dir = file.path(config_dir, "ring_events"),
    website_config_dir = file.path(config_dir, "website"),
    ring_events_intermediate_dir = file.path(intermediate_dir, "ring_events"),
    daily_counts_intermediate_dir = file.path(intermediate_dir, "daily_counts"),
    weather_intermediate_dir = file.path(intermediate_dir, "weather"),
    figures_dir = file.path(derived_dir, "figures"),
    summaries_dir = file.path(derived_dir, "summaries"),
    website_derived_dir = file.path(derived_dir, "website")
  )
}
