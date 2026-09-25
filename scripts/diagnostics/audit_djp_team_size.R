library(dplyr)
library(readr)
library(ggplot2)
library(scales)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

daily_coverage_path <- file.path(paths$curated_dir, "daily_coverage.csv")
qa_dir <- file.path(paths$qa_output_dir, "djp_team_size")
table_dir <- file.path(qa_dir, "tables")
figure_dir <- ngulia_figure_dir(file.path(qa_dir, "figures"))

dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("Audit DJP team-size codes")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date())
)

# Summarize code interpretation ------------------------------------------

code_dictionary <- daily_coverage |>
  filter(!is.na(djp_pax)) |>
  count(
    djp_pax,
    djp_team_size_total,
    djp_team_size_minimum,
    djp_team_size_interpretation,
    name = "n_dates",
    sort = TRUE
  )

coverage_by_season <- daily_coverage |>
  filter(if_any(c(djp_weather, djp_rain, djp_site, djp_tape, djp_pax), ~ !is.na(.x))) |>
  group_by(season) |>
  summarise(
    n_metadata_dates = n(),
    n_exact_team_size = sum(djp_team_size_interpretation %in% c("exact_total", "exact_base_plus_earthwatch")),
    n_minimum_only = sum(djp_team_size_interpretation == "minimum_plus_unspecified_earthwatch"),
    n_unknown = sum(djp_team_size_interpretation == "recorded_unknown"),
    median_team_size_minimum = median(djp_team_size_minimum, na.rm = TRUE),
    maximum_team_size_minimum = if_else(
      all(is.na(djp_team_size_minimum)),
      NA_real_,
      max(c(djp_team_size_minimum, 0), na.rm = TRUE)
    ),
    .groups = "drop"
  )

team_size_plot <- daily_coverage |>
  filter(!is.na(djp_team_size_minimum), ringing_happened) |>
  mutate(
    team_size_interpretation = recode(
      djp_team_size_interpretation,
      exact_total = "Exact total",
      exact_base_plus_earthwatch = "Exact base + Earthwatch",
      minimum_plus_unspecified_earthwatch = "Minimum + unspecified Earthwatch"
    )
  ) |>
  ggplot(aes(x = djp_team_size_minimum, y = total_birds_ringed)) +
  geom_point(aes(colour = team_size_interpretation), alpha = 0.35, size = 1.4) +
  geom_smooth(method = "loess", se = TRUE, colour = ngulia_colours[["blue"]]) +
  scale_y_sqrt(labels = label_number()) +
  scale_colour_manual(values = c(
    "Exact total" = ngulia_colours[["pale_teal"]],
    "Exact base + Earthwatch" = ngulia_colours[["gold"]],
    "Minimum + unspecified Earthwatch" = "#C97B36"
  )) +
  labs(
    title = "Positive daily catch and documented team size",
    subtitle = "PAX is labelled 'Team size - Ringers and others' in the source workbook. Association is descriptive, not an effort correction.",
    x = "Documented or minimum-known team size",
    y = "Daily birds ringed",
    colour = "PAX interpretation"
  ) +
  ngulia_theme(base_size = 11) +
  theme(legend.position = "top")

# Write outputs -----------------------------------------------------------

write_csv(code_dictionary, file.path(table_dir, "djp_team_size_code_dictionary.csv"))
write_csv(coverage_by_season, file.path(table_dir, "djp_team_size_coverage_by_season.csv"))
ggsave(file.path(figure_dir, "catch_by_documented_team_size.png"), team_size_plot, width = 10, height = 6.5, dpi = 220)

cli_alert_success("Wrote DJP team-size QA to {qa_dir}")
