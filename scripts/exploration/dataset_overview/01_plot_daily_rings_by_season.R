library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

daily_counts_path <- file.path(paths$curated_dir, "daily_counts.csv")
figure_dir <- ngulia_figure_dir(file.path(paths$exploration_output_dir, "dataset_overview", "figures"))
figure_path <- file.path(figure_dir, "daily_rings_by_season.png")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("Plot daily rings by season")

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
  group_by(season, ringing_date) |>
  summarise(total_ringed = sum(n_records, na.rm = TRUE), .groups = "drop") |>
  mutate(
    season_start = make_date(season, 10L, 20L),
    season_plot_date = as.Date("2000-10-20") + as.integer(ringing_date - season_start)
  )

# Plot daily capture matrix -----------------------------------------------

season_levels <- rev(sort(unique(daily_counts$season)))
month_breaks <- seq(
  floor_date(min(daily_counts$season_plot_date), unit = "month"),
  floor_date(max(daily_counts$season_plot_date), unit = "month"),
  by = "1 month"
)

daily_rings_plot <- ggplot(
  daily_counts |>
    mutate(season = factor(season, levels = season_levels)),
  aes(x = season_plot_date, y = season, fill = total_ringed)
) +
  geom_tile(width = 0.95, height = 0.95) +
  scale_x_date(
    breaks = month_breaks,
    labels = format(month_breaks, "%b"),
    expand = c(0, 0)
  ) +
  scale_fill_viridis_c(trans = "log1p", name = "Daily ring total") +
  labs(
    title = "Daily rings by season and day of year",
    subtitle = "January is shown after December within each ringing season; colour uses a log-scaled count gradient",
    x = "Day within season",
    y = "Season"
  ) +
  ngulia_theme(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

ngulia_save(figure_path, daily_rings_plot, width = 11, height = 8.5, dpi = 240)
cli_alert_success("Wrote daily-ring matrix to {figure_path}")
