library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(lubridate)
library(cli)
library(scales)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

curated_dir <- paths$curated_dir
figure_dir <- file.path(paths$figures_dir, "season_matrices")

daily_counts_path <- file.path(curated_dir, "daily_counts.csv")
daily_coverage_path <- file.path(curated_dir, "daily_coverage.csv")
season_matrices_pdf_path <- file.path(figure_dir, "season_matrices.pdf")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Helpers -----------------------------------------------------------------

to_season_plot_date <- function(date, season) {
  date <- as.Date(date)
  season_start <- make_date(season, 10L, 20L)
  as.Date("2000-10-20") + as.integer(date - season_start)
}

is_present_value <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    return(!is.na(x))
  }

  if (is.character(x)) {
    return(!is.na(x) & x != "")
  }

  !is.na(x)
}

build_season_grid <- function(seasons, plot_dates) {
  crossing(
    season = sort(unique(seasons)),
    season_plot_date = seq(min(plot_dates), max(plot_dates), by = "1 day")
  )
}

build_season_axis_breaks <- function(plot_dates) {
  tibble(
    month_start = seq(
      floor_date(min(plot_dates), unit = "month"),
      floor_date(max(plot_dates), unit = "month"),
      by = "1 month"
    )
  )
}

summarize_group_coverage <- function(data, variable_names) {
  data |>
    mutate(
      n_group_present = rowSums(
        across(all_of(variable_names), \(col) is_present_value(col))
      ),
      n_group_variables = length(variable_names),
      coverage = case_when(
        !has_metadata_day ~ "no_documented_coverage",
        n_group_present == n_group_variables ~ "all_variables_available",
        n_group_present == 0 ~ "no_group_variables_available",
        TRUE ~ "some_variables_missing"
      )
    )
}

infer_metadata_day <- function(data) {
  rowSums(
    as.data.frame(lapply(data, is_present_value))
  ) > 0
}

make_matrix_plot <- function(data, fill_var, title, subtitle, fill_scale) {
  season_levels <- rev(sort(unique(data$season)))
  season_axis_breaks <- build_season_axis_breaks(data$season_plot_date)

  ggplot(
    data |>
      mutate(season = factor(season, levels = season_levels)),
    aes(x = season_plot_date, y = season, fill = .data[[fill_var]])
  ) +
    geom_tile(width = 0.95, height = 0.95, color = NA) +
    scale_x_date(
      breaks = season_axis_breaks$month_start,
      labels = format(season_axis_breaks$month_start, "%b"),
      expand = c(0, 0)
    ) +
    fill_scale +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Day within season",
      y = "Season"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(face = "bold"),
      legend.position = "right"
    )
}

# Read data ---------------------------------------------------------------

cli_h1("Plot season matrices")

daily_counts <- read_csv(
  daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(
    ringing_date = col_date(),
    season = col_integer(),
    n_records = col_double(),
    .default = col_character()
  )
) |>
  rename(date = ringing_date)

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  col_types = cols(
    ringing_date = col_date(),
    season = col_integer(),
    .default = col_guess()
  )
) |>
  rename(date = ringing_date)

# Daily count matrix ------------------------------------------------------

daily_count_totals <- daily_counts |>
  group_by(season, date) |>
  summarise(total_ringed = sum(n_records, na.rm = TRUE), .groups = "drop") |>
  mutate(season_plot_date = to_season_plot_date(date, season))

season_plot_window <- range(daily_count_totals$season_plot_date, na.rm = TRUE)
season_plot_window <- range(
  to_season_plot_date(daily_coverage$date, daily_coverage$season),
  na.rm = TRUE
)

count_grid <- build_season_grid(
  seasons = daily_count_totals$season,
  plot_dates = daily_count_totals$season_plot_date
) |>
  left_join(
    daily_count_totals |>
      select(season, season_plot_date, total_ringed),
    by = c("season", "season_plot_date")
  )

counts_plot <- make_matrix_plot(
  data = count_grid,
  fill_var = "total_ringed",
  title = "Daily rings by season and day of year",
  subtitle = "Based on data/04_curated/daily_counts.csv; January is shown after December within each season; fill uses a log-scaled continuous count gradient",
  fill_scale = scale_fill_viridis_c(
    trans = "log1p",
    na.value = "#f1efe8",
    name = "Daily ring total"
  )
)

# Metadata coverage matrices ----------------------------------------------

moon_variables <- c(
  "moon_days_from_new_moon",
  "moon_illumination_fraction",
  "moon_phase_name"
)

djp_variables <- c(
  "djp_weather",
  "djp_rain",
  "djp_site",
  "djp_tape",
  "djp_pax"
)

era5_variables <- setdiff(
  names(daily_coverage),
  c(
    "date",
    "season",
    "total_birds_ringed",
    "ringing_happened",
    "djp_total_birds_ringed",
    "djp_moon_days_from_new_moon",
    moon_variables,
    djp_variables
  )
)

metadata_plot_dates <- to_season_plot_date(daily_coverage$date, daily_coverage$season)
metadata_presence_variables <- c(
  "djp_moon_days_from_new_moon",
  djp_variables,
  era5_variables
)

metadata_grid <- build_season_grid(
  seasons = daily_coverage$season,
  plot_dates = season_plot_window
) |>
  left_join(
    daily_coverage |>
      mutate(season_plot_date = to_season_plot_date(date, season)),
    by = c("season", "season_plot_date")
  ) |>
  mutate(has_metadata_day = infer_metadata_day(pick(all_of(metadata_presence_variables))))

djp_coverage_data <- summarize_group_coverage(metadata_grid, djp_variables)

all_available_n <- sum(djp_coverage_data$coverage == "all_variables_available")
some_missing_n <- sum(djp_coverage_data$coverage == "some_variables_missing")
none_available_n <- sum(djp_coverage_data$coverage == "no_group_variables_available")
no_row_n <- sum(djp_coverage_data$coverage == "no_documented_coverage")

djp_metadata_plot <- make_matrix_plot(
  data = djp_coverage_data,
  fill_var = "coverage",
  title = "Coverage of DJP metadata variables",
  subtitle = paste0(
    "DJP coverage across ", length(djp_variables), " variables",
    "; all available: ", comma(all_available_n),
    "; some missing: ", comma(some_missing_n),
    "; none available on documented-coverage day: ", comma(none_available_n),
    "; no documented coverage on season-day: ", comma(no_row_n)
  ),
  fill_scale = scale_fill_manual(
    values = c(
      all_variables_available = "#2c7fb8",
      some_variables_missing = "#fdae6b",
      no_group_variables_available = "#cb181d",
      no_documented_coverage = "#f1efe8"
    ),
    breaks = c(
      "all_variables_available",
      "some_variables_missing",
      "no_group_variables_available",
      "no_documented_coverage"
    ),
    labels = c(
      "All variables available",
      "Some variables missing",
      "No variables available on documented-coverage day",
      "No documented coverage for this season-day"
    ),
    name = "Coverage state"
  )
)

# Metadata versus rings presence ------------------------------------------

presence_plot_dates <- c(daily_count_totals$season_plot_date, metadata_plot_dates)
presence_seasons <- c(daily_count_totals$season, daily_coverage$season)

metadata_ring_presence <- build_season_grid(
  seasons = presence_seasons,
  plot_dates = season_plot_window
) |>
  left_join(
    daily_count_totals |>
      transmute(
        season,
        season_plot_date,
        has_ring_day = total_ringed > 0
      ),
    by = c("season", "season_plot_date")
  ) |>
  left_join(
    daily_coverage |>
      transmute(
        season,
        season_plot_date = to_season_plot_date(date, season),
        has_metadata_day = infer_metadata_day(pick(all_of(metadata_presence_variables)))
      ),
    by = c("season", "season_plot_date")
  ) |>
  mutate(
    has_ring_day = coalesce(has_ring_day, FALSE),
    has_metadata_day = coalesce(has_metadata_day, FALSE),
    presence_state = case_when(
      has_metadata_day & has_ring_day ~ "both_metadata_and_rings",
      has_metadata_day & !has_ring_day ~ "metadata_only",
      !has_metadata_day & has_ring_day ~ "rings_only",
      TRUE ~ "neither_coverage_nor_rings"
    )
  )

presence_plot <- make_matrix_plot(
  data = metadata_ring_presence,
  fill_var = "presence_state",
  title = "Metadata coverage versus days with at least one ring",
  subtitle = "Compares metadata availability in data/04_curated/daily_coverage.csv against days with at least one ring in data/04_curated/daily_counts.csv",
  fill_scale = scale_fill_manual(
    values = c(
      both_metadata_and_rings = "#2b8cbe",
      metadata_only = "#7bccc4",
      rings_only = "#f16913",
      neither_coverage_nor_rings = "#f1efe8"
    ),
    breaks = c(
      "both_metadata_and_rings",
      "metadata_only",
      "rings_only",
      "neither_coverage_nor_rings"
    ),
    labels = c(
      "Metadata available and at least one ring",
      "Metadata available but no rings",
      "At least one ring but no metadata",
      "Neither metadata nor rings"
    ),
    name = "Presence state"
  )
)

# Write output ------------------------------------------------------------

pdf(season_matrices_pdf_path, width = 11, height = 8.5, onefile = TRUE)
print(counts_plot)
print(djp_metadata_plot)
print(presence_plot)
dev.off()

cli_alert_success("Wrote season matrices PDF to {season_matrices_pdf_path}")
