library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(lubridate)
library(stringr)
library(cli)
library(scales)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

figure_dir <- file.path(paths$qa_output_dir, "ring_events", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

ring_events_path <- file.path(paths$curated_dir, "ring_events.csv")
coverage_csv_path <- file.path(figure_dir, "ring_event_variable_coverage_by_day.csv")
coverage_pdf_path <- file.path(figure_dir, "ring_event_variable_coverage_by_day.pdf")

# Read data ---------------------------------------------------------------

cli_h1("Plot ring-event variable coverage by day")

ring_events <- read_csv(
  ring_events_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  mutate(
    season = as.integer(season),
    ringing_date = as.Date(ringing_date),
    day_of_year = yday(ringing_date),
    has_time = str_detect(datetime, "T"),
    has_wing = !is.na(na_if(str_trim(wing), "")),
    has_weight = !is.na(na_if(str_trim(weight), "")),
    has_fat_ngulia = !is.na(na_if(str_trim(fat_ngulia), "")),
    has_fat_kaiser = !is.na(na_if(str_trim(fat_kaiser), "")),
    has_age = !is.na(na_if(str_trim(age), "")),
    has_sex = !is.na(na_if(str_trim(sex), ""))
  )

variable_labels <- c(
  has_time = "Capture time",
  has_wing = "Wing length",
  has_weight = "Weight",
  has_fat_ngulia = "Fat score (Ngulia)",
  has_fat_kaiser = "Fat score (Kaiser)",
  has_age = "Age",
  has_sex = "Sex"
)

coverage_by_day <- ring_events |>
  group_by(season, ringing_date, day_of_year) |>
  summarise(
    n_ring_events = n(),
    across(all_of(names(variable_labels)), ~ sum(.x, na.rm = TRUE)),
    .groups = "drop"
  ) |>
  mutate(
    season_plot_date = as.Date("2000-10-01") + if_else(
      month(ringing_date) >= 10L,
      as.integer(ringing_date - make_date(season, 10L, 1L)),
      92L + day_of_year - 1L
    )
  ) |>
  pivot_longer(
    cols = all_of(names(variable_labels)),
    names_to = "variable",
    values_to = "n_with_data"
  ) |>
  mutate(
    variable = recode(variable, !!!variable_labels),
    pct_with_data = 100 * n_with_data / n_ring_events
  )

write_csv(coverage_by_day, coverage_csv_path, na = "")

# Plot --------------------------------------------------------------------

month_breaks <- seq(as.Date("2000-10-01"), as.Date("2001-01-01"), by = "1 month")

make_coverage_plot <- function(variable_name) {
  ggplot(
    filter(coverage_by_day, variable == variable_name),
    aes(x = season_plot_date, y = factor(season), fill = pct_with_data)
  ) +
    geom_tile(width = 0.98, height = 0.98, color = NA) +
    scale_x_date(
      breaks = month_breaks,
      labels = c("Oct", "Nov", "Dec", "Jan"),
      limits = c(as.Date("2000-10-01"), as.Date("2001-02-01")),
      expand = c(0, 0)
    ) +
    scale_fill_viridis_c(
      name = "% of ring events",
      limits = c(0, 100),
      breaks = c(0, 25, 50, 75, 100),
      option = "C"
    ) +
    labs(
      title = paste("Daily coverage:", variable_name),
      subtitle = "Each tile is a calendar day; color shows the share of that day's ring events with a recorded value. Blank dates had no ring events.",
      x = "Day within season",
      y = "Year"
    ) +
    ngulia_theme(base_size = 12) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(hjust = 0.5),
      legend.position = "bottom"
    )
}

pdf(coverage_pdf_path, width = 12, height = 8.5, onefile = TRUE)
for (variable_name in unname(variable_labels)) {
  print(make_coverage_plot(variable_name))
}
dev.off()

cli_alert_success("Wrote daily coverage table to {coverage_csv_path}")
cli_alert_success("Wrote daily coverage matrix to {coverage_pdf_path}")
