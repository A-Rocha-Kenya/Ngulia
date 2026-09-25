library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(ggplot2)
library(scales)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
paths <- get_data_paths(project_dir)

output_dir <- file.path(paths$qa_output_dir, "daily_net_sites")
figure_dir <- ngulia_figure_dir(file.path(output_dir, "figures"))
table_dir <- file.path(output_dir, "tables")
daily_coverage_path <- file.path(paths$curated_dir, "daily_coverage.csv")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("Plot temporal net-site coverage")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
)

site_levels <- c(
  "back_bush", "front_bush", "outside_night_nets", "lodge_veranda"
)

site_labels <- c(
  back_bush = "Back bush",
  front_bush = "Front bush",
  outside_night_nets = "Night nets",
  lodge_veranda = "Lodge veranda"
)

site_colours <- c(
  back_bush = ngulia_colours[["blue"]],
  front_bush = ngulia_colours[["teal"]],
  outside_night_nets = ngulia_colours[["gold"]],
  lodge_veranda = ngulia_colours[["purple"]]
)
site_colours_named <- setNames(unname(site_colours), unname(site_labels[site_levels]))

# Summarize category prevalence --------------------------------------------
# Categories are not mutually exclusive: a date can contain front bush and
# outside night nets, so category percentages can sum to more than 100%.

category_coverage <- daily_coverage |>
  filter(ringing_happened) |>
  select(season, net_sites_observed) |>
  expand_grid(site = site_levels) |>
  mutate(
    present = !is.na(net_sites_observed) & str_detect(net_sites_observed, fixed(site))
  ) |>
  group_by(season, site) |>
  summarise(
    n_positive_catch_dates = n(),
    n_dates_present = sum(present),
    coverage_fraction = n_dates_present / n_positive_catch_dates,
    .groups = "drop"
  ) |>
  mutate(
    site = factor(site, levels = site_levels, labels = unname(site_labels[site_levels])),
    panel = "Site categories"
  )

write_csv(category_coverage, file.path(table_dir, "net_site_category_coverage_by_season.csv"))

# Plot --------------------------------------------------------------------

plot <- ggplot() +
  geom_line(
    data = category_coverage,
    aes(season, coverage_fraction, colour = site, group = site),
    linewidth = 0.8
  ) +
  geom_point(
    data = category_coverage,
    aes(season, coverage_fraction, colour = site),
    size = 1.2
  ) +
  scale_colour_manual(
    values = site_colours_named,
    name = "Recorded category"
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(1970, 2020, by = 5)) +
  labs(
    title = "Temporal coverage of recorded net sites",
    subtitle = "Percent of positive-catch dates in each ringing season; categories can overlap",
    x = "Ringing season",
    y = "Dates (%)",
    caption = paste(
      "Recorded daily use, not changes in physical net positions. Blank site fields are unknown;",
      "each positive-catch date is counted for every recorded site label."
    )
  ) +
  ngulia_theme(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.caption = element_text(hjust = 0)
  )

ngulia_save(
  file.path(figure_dir, "net_site_coverage_by_season.png"),
  plot,
  width = 12,
  height = 5.5,
  dpi = 220
)

cli_alert_success("Wrote net-site coverage figure and tables to {output_dir}")
