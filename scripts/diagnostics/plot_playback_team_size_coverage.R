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

output_dir <- file.path(paths$qa_output_dir, "daily_playback_team_size")
figure_dir <- ngulia_figure_dir(file.path(output_dir, "figures"))
table_dir <- file.path(output_dir, "tables")
daily_coverage_path <- file.path(paths$curated_dir, "daily_coverage.csv")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("Plot temporal playback and team-size coverage")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
)

# Playback ----------------------------------------------------------------

playback_levels <- c("front_tapes", "behind_lodge_tapes", "none")
playback_labels <- c(
  front_tapes = "Front tapes",
  behind_lodge_tapes = "Behind-lodge tapes",
  none = "No night tape recorded"
)
playback_colours <- c(
  front_tapes = ngulia_colours[["teal"]],
  behind_lodge_tapes = ngulia_colours[["gold"]],
  none = ngulia_colours[["red"]]
)
playback_colours_named <- setNames(
  unname(playback_colours),
  unname(playback_labels[playback_levels])
)

playback_categories <- daily_coverage |>
  filter(ringing_happened) |>
  select(season, djp_tape) |>
  expand_grid(category = playback_levels) |>
  mutate(
    present = !is.na(djp_tape) & str_detect(djp_tape, fixed(category))
  ) |>
  group_by(season, category) |>
  summarise(
    n_positive_catch_dates = n(),
    n_dates_present = sum(present),
    coverage_fraction = n_dates_present / n_positive_catch_dates,
    .groups = "drop"
  ) |>
  mutate(
    category = factor(category, levels = playback_levels, labels = unname(playback_labels[playback_levels])),
    panel = "Playback categories"
  )

write_csv(playback_categories, file.path(table_dir, "playback_category_coverage_by_season.csv"))

playback_plot <- ggplot() +
  geom_line(
    data = playback_categories,
    aes(season, coverage_fraction, colour = category, group = category),
    linewidth = 0.8
  ) +
  geom_point(
    data = playback_categories,
    aes(season, coverage_fraction, colour = category),
    size = 1.2
  ) +
  scale_colour_manual(values = playback_colours_named, name = "Recorded category") +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(1970, 2020, by = 5)) +
  labs(
    title = "Temporal coverage of recorded playback",
    subtitle = "Percent of positive-catch dates; front and behind-lodge are source locations",
    x = "Ringing season",
    y = "Dates (%)",
    caption = "The source does not identify night-net versus bush-net speakers. Blank tape cells within DJP metadata mean none; other dates remain unknown."
  ) +
  ngulia_theme(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.caption = element_text(hjust = 0)
  )

ngulia_save(
  file.path(figure_dir, "playback_coverage_by_season.png"),
  playback_plot,
  width = 12,
  height = 5.5,
  dpi = 220
)

# Team size ---------------------------------------------------------------

season_dates <- daily_coverage |>
  count(season, name = "n_calendar_dates")

team_size_summary <- daily_coverage |>
  filter(!is.na(djp_team_size_minimum)) |>
  group_by(season) |>
  summarise(
    n_dates_recorded = n(),
    q25 = quantile(djp_team_size_minimum, 0.25),
    median = median(djp_team_size_minimum),
    q75 = quantile(djp_team_size_minimum, 0.75),
    .groups = "drop"
  ) |>
  left_join(season_dates, by = "season") |>
  mutate(
    panel = "Recorded team size",
    coverage_fraction = n_dates_recorded / n_calendar_dates
  )

team_size_information <- daily_coverage |>
  group_by(season) |>
  summarise(
    n_calendar_dates = n(),
    n_dates_recorded = sum(!is.na(djp_team_size_minimum)),
    n_dates_exact = sum(djp_team_size_interpretation %in% c("exact_total", "exact_base_plus_earthwatch")),
    n_dates_lower_bound = sum(djp_team_size_interpretation == "minimum_plus_unspecified_earthwatch"),
    .groups = "drop"
  ) |>
  mutate(
    recorded_fraction = n_dates_recorded / n_calendar_dates,
    exact_fraction = n_dates_exact / n_calendar_dates,
    lower_bound_fraction = n_dates_lower_bound / n_calendar_dates,
    unknown_fraction = 1 - recorded_fraction
  ) |>
  pivot_longer(
    c(recorded_fraction, exact_fraction, lower_bound_fraction, unknown_fraction),
    names_to = "measure",
    values_to = "fraction"
  ) |>
  mutate(
    measure = recode(
      measure,
      recorded_fraction = "Any numeric team size",
      exact_fraction = "Exact value",
      lower_bound_fraction = "Lower bound only",
      unknown_fraction = "Team size unknown"
    ),
    panel = "Team-size information availability"
  )

write_csv(team_size_summary, file.path(table_dir, "team_size_summary_by_season.csv"))
write_csv(team_size_information, file.path(table_dir, "team_size_information_coverage_by_season.csv"))

team_size_plot <- ggplot() +
  geom_ribbon(
    data = team_size_summary,
    aes(season, ymin = q25, ymax = q75),
    fill = ngulia_colours[["teal"]],
    alpha = 0.25
  ) +
  geom_line(
    data = team_size_summary,
    aes(season, median),
    colour = ngulia_colours[["teal"]],
    linewidth = 0.9
  ) +
  geom_point(
    data = team_size_summary,
    aes(season, median),
    colour = ngulia_colours[["teal"]],
    size = 1.3
  ) +
  geom_line(
    data = team_size_information,
    aes(season, fraction * 30, linetype = measure, group = measure),
    colour = ngulia_colours[["muted"]],
    linewidth = 0.7
  ) +
  facet_grid(rows = vars(panel), scales = "free_y") +
  scale_linetype_manual(
    values = c(
      "Any numeric team size" = "solid",
      "Exact value" = "dashed",
      "Lower bound only" = "dotdash",
      "Team size unknown" = "dotted"
    ),
    name = "Field status"
  ) +
  scale_x_continuous(breaks = seq(1970, 2020, by = 5)) +
  scale_y_continuous(
    name = "People",
    breaks = seq(0, 30, by = 5),
    sec.axis = sec_axis(~ . / 30, name = "Dates (%)", labels = label_percent(accuracy = 1))
  ) +
  labs(
    title = "Temporal coverage of recorded team size",
    subtitle = "Top: median and interquartile range of the recorded minimum team size; bottom: field availability",
    x = "Ringing season",
    caption = "The minimum team size is exact where possible, but is a lower bound when Earthwatch participant numbers were unspecified."
  ) +
  ngulia_theme(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    strip.text.y = element_text(angle = 0),
    plot.caption = element_text(hjust = 0)
  )

ngulia_save(
  file.path(figure_dir, "team_size_coverage_by_season.png"),
  team_size_plot,
  width = 12,
  height = 7.5,
  dpi = 220
)

cli_alert_success("Wrote playback and team-size figures and tables to {output_dir}")
