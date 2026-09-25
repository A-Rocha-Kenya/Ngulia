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
qa_dir <- file.path(paths$qa_output_dir, "daily_effort")
table_dir <- file.path(qa_dir, "tables")
figure_dir <- ngulia_figure_dir(file.path(qa_dir, "figures"))

dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Read and validate -------------------------------------------------------

cli_h1("Summarize daily effort evidence")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date())
)

stopifnot(nrow(daily_coverage) == n_distinct(daily_coverage$ringing_date))

# Summarize evidence and eligibility -------------------------------------

effort_status_counts <- daily_coverage |>
  count(effort_status, name = "n_dates") |>
  mutate(fraction_calendar_dates = n_dates / sum(n_dates)) |>
  arrange(desc(n_dates))

effort_coverage_by_season <- daily_coverage |>
  transmute(
    season,
    documented_operation = effort_status == "documented_operation",
    inferred_operation = effort_status == "inferred_operation_from_positive_catch",
    documented_no_operation = effort_status == "documented_no_operation",
    conflicting_evidence = effort_status == "conflicting_positive_catch_and_no_site",
    unknown_effort = effort_status == "unknown"
  ) |>
  pivot_longer(-season, names_to = "metric", values_to = "available") |>
  group_by(season, metric) |>
  summarise(
    n_calendar_dates = n(),
    n_dates = sum(available),
    fraction_calendar_dates = mean(available),
    .groups = "drop"
  )

eligibility_counts <- daily_coverage |>
  summarise(
    n_calendar_dates = n(),
    n_positive_catch_dates = sum(ringing_happened),
    n_known_or_inferred_operation_dates = sum(effort_status %in% c(
      "documented_operation", "inferred_operation_from_positive_catch",
      "conflicting_positive_catch_and_no_site"
    )),
    n_documented_operation_zero_catch = sum(
      effort_status == "documented_operation" & !ringing_happened
    )
  )

effort_conflicts <- daily_coverage |>
  filter(effort_status == "conflicting_positive_catch_and_no_site")

coverage_plot <- effort_coverage_by_season |>
  filter(metric %in% c(
    "documented_operation",
    "inferred_operation",
    "documented_no_operation",
    "unknown_effort"
  )) |>
  mutate(metric = recode(
    metric,
    documented_operation = "Documented active site",
    inferred_operation = "Operation inferred from catch",
    documented_no_operation = "Documented no operation",
    unknown_effort = "Effort unknown"
  )) |>
  ggplot(aes(season, metric, fill = fraction_calendar_dates)) +
  geom_tile() +
  scale_fill_viridis_c(labels = label_percent(), limits = c(0, 1), option = "C") +
  scale_x_continuous(breaks = seq(1970, 2020, by = 10)) +
  labs(
    title = "Daily effort evidence by ringing season",
    subtitle = "Recorded net-site states are separate from operation inferred from a positive catch.",
    x = "Season",
    y = NULL,
    fill = "Dates"
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid = element_blank(), axis.text.y = element_text(colour = "#25343B"))

# Write outputs -----------------------------------------------------------

write_csv(effort_status_counts, file.path(table_dir, "effort_status_counts.csv"))
write_csv(effort_coverage_by_season, file.path(table_dir, "effort_coverage_by_season.csv"))
write_csv(eligibility_counts, file.path(table_dir, "effort_model_eligibility.csv"))
write_csv(effort_conflicts, file.path(table_dir, "effort_evidence_conflicts.csv"))
ggsave(file.path(figure_dir, "daily_effort_coverage_by_season.png"), coverage_plot, width = 12, height = 5.5, dpi = 220)

cli_alert_success("Wrote daily effort QA to {qa_dir}")
