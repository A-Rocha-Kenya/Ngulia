library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(scales)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

daily_coverage_path <- file.path(paths$curated_dir, "daily_coverage.csv")
qa_dir <- file.path(paths$qa_output_dir, "daily_covariate_coverage")
table_dir <- file.path(qa_dir, "tables")
figure_dir <- ngulia_figure_dir(file.path(qa_dir, "figures"))

dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Read and summarize coverage --------------------------------------------

cli_h1("Summarize daily covariate coverage")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date())
)

coverage_by_season <- daily_coverage |>
  transmute(
    season,
    positive_catch = ringing_happened,
    djp_metadata = if_any(c(djp_weather, djp_rain, djp_site, djp_tape, djp_pax), ~ !is.na(.x)),
    observed_mist_evidence = !is.na(mist_observation),
    unified_mist_distribution = !is.na(mist_probability_good),
    observed_rain = !is.na(djp_rain),
    observed_playback = !is.na(djp_tape),
    interpretable_net_site = !is.na(djp_site) & djp_site != "unknown",
    interpretable_staffing = djp_team_size_interpretation %in% c(
      "exact_total", "exact_base_plus_earthwatch", "minimum_plus_unspecified_earthwatch"
    ),
    documented_operation = effort_status == "documented_operation",
    operation_known_or_inferred = effort_status %in% c(
      "documented_operation", "inferred_operation_from_positive_catch",
      "conflicting_positive_catch_and_no_site"
    ),
    era5_weather = if_all(c(
      total_precipitation_00_08_mm, wind_speed_10m_mean_ms,
      temperature_2m_mean_c, surface_pressure_mean_hpa
    ), ~ !is.na(.x)),
    lunar_metrics = !is.na(moon_days_from_new_moon)
  ) |>
  pivot_longer(-season, names_to = "covariate", values_to = "available") |>
  group_by(season, covariate) |>
  summarise(
    n_calendar_dates = n(),
    n_available = sum(available),
    coverage_fraction = mean(available),
    .groups = "drop"
  )

coverage_overall <- coverage_by_season |>
  group_by(covariate) |>
  summarise(
    n_calendar_dates = sum(n_calendar_dates),
    n_available = sum(n_available),
    coverage_fraction = n_available / n_calendar_dates,
    first_season = first(season[n_available > 0], default = NA_real_),
    last_season = last(season[n_available > 0], default = NA_real_),
    .groups = "drop"
  ) |>
  arrange(desc(coverage_fraction))

coverage_plot <- coverage_by_season |>
  mutate(
    covariate = recode(
      covariate,
      positive_catch = "Positive catch recorded",
      djp_metadata = "Any DJP metadata",
      observed_mist = "Observed mist status",
      modeled_mist = "ERA5 modeled mist",
      observed_rain = "DJP rain field",
      observed_playback = "Playback field",
      interpretable_net_site = "Interpretable net-site field",
      interpretable_staffing = "Staffing field present",
      documented_operation = "Documented active net site",
      operation_known_or_inferred = "Known/inferred operation",
      era5_weather = "Complete ERA5 weather",
      lunar_metrics = "Lunar metrics"
    )
  ) |>
  ggplot(aes(x = season, y = covariate, fill = coverage_fraction)) +
  geom_tile() +
  scale_fill_viridis_c(labels = label_percent(), limits = c(0, 1), option = "C") +
  scale_x_continuous(breaks = seq(1970, 2020, by = 10)) +
  labs(
    title = "Daily covariate coverage by ringing season",
    subtitle = "Fraction of calendar dates with each field. A positive catch is not equivalent to known ringing effort.",
    x = "Season",
    y = NULL,
    fill = "Coverage"
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid = element_blank(), axis.text.y = element_text(colour = "#25343B"))

# Write outputs -----------------------------------------------------------

write_csv(coverage_by_season, file.path(table_dir, "daily_covariate_coverage_by_season.csv"))
write_csv(coverage_overall, file.path(table_dir, "daily_covariate_coverage_overall.csv"))
ggsave(file.path(figure_dir, "daily_covariate_coverage_by_season.png"), coverage_plot, width = 12, height = 6.5, dpi = 220)

cli_alert_success("Wrote daily covariate coverage QA to {qa_dir}")
