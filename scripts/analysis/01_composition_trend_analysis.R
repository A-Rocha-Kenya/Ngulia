library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(ggplot2)
library(mgcv)
library(cli)

# Paths -------------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

analysis_dir <- file.path(paths$derived_dir, "analysis", "composition_trends")
figure_dir <- file.path(analysis_dir, "figures")
model_dir <- file.path(analysis_dir, "models")
summary_dir <- file.path(analysis_dir, "summary_tables")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("Ngulia composition trend analysis")

daily_counts <- read_csv(
  file.path(paths$curated_dir, "daily_counts.csv"),
  show_col_types = FALSE,
  col_types = cols_only(
    ringing_date = col_date(),
    season = col_integer(),
    avibase_id = col_character(),
    common_name = col_character(),
    n_records = col_double()
  )
) |>
  rename(count = n_records)

documented_days <- read_csv(
  file.path(paths$curated_dir, "daily_coverage.csv"),
  show_col_types = FALSE,
  col_types = cols_only(
    ringing_date = col_date(),
    season = col_integer(),
    ringing_happened = col_logical()
  )
) |>
  filter(ringing_happened) |>
  select(ringing_date, season)

# Focal species -----------------------------------------------------------

# Retain species with enough records and seasonal coverage for trend models.

focal_species <- daily_counts |>
  group_by(avibase_id, common_name) |>
  summarise(
    total_count = sum(count),
    n_seasons_observed = n_distinct(season),
    .groups = "drop"
  ) |>
  filter(total_count >= 500, n_seasons_observed >= 10) |>
  arrange(desc(total_count), common_name)

cli_alert_info("Selected {nrow(focal_species)} focal species.")

# Complete daily species matrix ------------------------------------------

# Missing species records on a documented ringing day represent zero catch.

focal_counts <- daily_counts |>
  semi_join(focal_species, by = "avibase_id") |>
  select(ringing_date, avibase_id, count)

documented_species_days <- expand_grid(
  ringing_date = documented_days$ringing_date,
  avibase_id = focal_species$avibase_id
) |>
  left_join(focal_counts, by = c("ringing_date", "avibase_id")) |>
  mutate(count = replace_na(count, 0)) |>
  left_join(focal_species |> select(avibase_id, common_name), by = "avibase_id") |>
  left_join(documented_days, by = "ringing_date") |>
  group_by(ringing_date) |>
  mutate(total_focal_count = sum(count)) |>
  ungroup() |>
  mutate(
    other_focal_count = total_focal_count - count,
    proportion = if_else(total_focal_count > 0, count / total_focal_count, NA_real_)
  )

model_data <- documented_species_days |>
  filter(total_focal_count > 0) |>
  mutate(day_of_season = as.integer(ringing_date - as.Date(sprintf("%s-10-01", season))))

season_center <- stats::median(model_data$season, na.rm = TRUE)
prediction_seasons <- sort(unique(model_data$season))
k_year <- min(8, n_distinct(model_data$season) - 1)
k_day <- min(12, n_distinct(model_data$day_of_season) - 1)

model_data <- model_data |>
  mutate(season_centered = season - season_center)

# QA checks ---------------------------------------------------------------

cli_h2("QA checks")

undocumented_count_days <- focal_counts |>
  distinct(ringing_date) |>
  anti_join(documented_days, by = "ringing_date")

if (nrow(undocumented_count_days) == 0) {
  cli_alert_success("All focal-count dates are documented ringing days.")
} else {
  cli_abort("Some focal-count dates are not documented ringing days.")
}

duplicate_rows <- documented_species_days |>
  count(ringing_date, avibase_id) |>
  filter(n > 1)

if (nrow(duplicate_rows) == 0) {
  cli_alert_success("No duplicated ringing_date x species rows after completion.")
} else {
  cli_abort("Found duplicated ringing_date x species rows after completion.")
}

species_per_day <- documented_species_days |>
  count(ringing_date, name = "n_species") |>
  filter(n_species != nrow(focal_species))

if (nrow(species_per_day) == 0) {
  cli_alert_success("All documented days have all focal species after completion.")
} else {
  cli_abort("Some documented days do not have all focal species after completion.")
}

original_focal_daily_totals <- focal_counts |>
  group_by(ringing_date) |>
  summarise(original_total = sum(count), .groups = "drop")

reconstructed_focal_daily_totals <- documented_species_days |>
  group_by(ringing_date) |>
  summarise(reconstructed_total = sum(count), .groups = "drop")

daily_total_mismatches <- original_focal_daily_totals |>
  left_join(reconstructed_focal_daily_totals, by = "ringing_date") |>
  filter(is.na(reconstructed_total) | original_total != reconstructed_total)

if (nrow(daily_total_mismatches) == 0) {
  cli_alert_success("Reconstructed daily focal totals match the original data.")
} else {
  cli_abort("Reconstructed daily focal totals do not match original focal totals.")
}

proportion_sums <- model_data |>
  group_by(ringing_date) |>
  summarise(proportion_sum = sum(proportion), .groups = "drop") |>
  filter(abs(proportion_sum - 1) > 1e-8)

if (nrow(proportion_sums) == 0) {
  cli_alert_success("Daily proportions sum to 1 on positive-catch days.")
} else {
  cli_abort("Daily proportions do not sum to 1 on all positive-catch days.")
}

# Fit species-wise GAMs ---------------------------------------------------

# These models estimate relative representation in the Ngulia catch,
# not absolute abundance. The total daily focal catch defines the denominator
# for each daily species proportion. Phenology is modelled with species-specific
# day_of_season smooths. Weather and moon are intentionally not included because
# conditioning on daily total catch should absorb much shared catchability variation.

fit_species_gam <- function(species_id) {
  species_data <- model_data |>
    filter(avibase_id == species_id)

  n_positive_days <- sum(species_data$count > 0)

  if (n_positive_days < 20) {
    return(list(model = NULL, status = "skipped", reason = "fewer than 20 positive days"))
  }

  if (n_distinct(species_data$proportion) < 2) {
    return(list(model = NULL, status = "skipped", reason = "insufficient proportion variation"))
  }

  model <- mgcv::gam(
    cbind(count, other_focal_count) ~ s(season_centered, k = k_year) + s(day_of_season, k = k_day),
    data = species_data,
    family = stats::quasibinomial(),
    method = "REML"
  )

  list(model = model, status = "fitted", reason = NA_character_, k_year = k_year, k_day = k_day)
}

cli_h2("Fitting species-wise GAMs")

safe_fit_species_gam <- safely(fit_species_gam, otherwise = NULL)

fit_results <- focal_species |>
  mutate(result = map(avibase_id, safe_fit_species_gam))

model_status <- fit_results |>
  transmute(
    avibase_id,
    common_name,
    total_count,
    n_seasons_observed,
    status = map_chr(result, \(x) {
      if (!is.null(x$error) || is.null(x$result)) "failed" else x$result$status
    }),
    reason = map_chr(result, \(x) {
      if (!is.null(x$error)) conditionMessage(x$error) else x$result$reason
    }),
    k_year = map_int(result, \(x) {
      if (!is.null(x$error) || is.null(x$result$k_year)) NA_integer_ else x$result$k_year
    }),
    k_day = map_int(result, \(x) {
      if (!is.null(x$error) || is.null(x$result$k_day)) NA_integer_ else x$result$k_day
    })
  )

fitted_models <- fit_results |>
  mutate(model = map(result, \(x) if (is.null(x$error)) x$result$model else NULL)) |>
  select(avibase_id, common_name, model) |>
  filter(!map_lgl(model, is.null))

write_csv(focal_species, file.path(summary_dir, "focal_species.csv"), na = "")
write_csv(model_status, file.path(summary_dir, "model_status.csv"), na = "")
saveRDS(fitted_models, file.path(model_dir, "species_gam_models.rds"))

cli_alert_success("Fitted {nrow(fitted_models)} of {nrow(focal_species)} focal species.")

# Standardized predictions -----------------------------------------------

# Predictions use link-scale 95% intervals, transformed to proportions.

predict_species_year_index <- function(species_id, model) {
  species_data <- model_data |>
    filter(avibase_id == species_id)

  median_day <- species_data |>
    filter(count > 0) |>
    pull(day_of_season) |>
    stats::median(na.rm = TRUE)

  prediction_data <- tibble(
    season = prediction_seasons,
    season_centered = season - season_center,
    day_of_season = median_day
  )

  predictions <- stats::predict(model, newdata = prediction_data, type = "link", se.fit = TRUE)
  fit <- stats::plogis(predictions$fit)
  lower <- stats::plogis(predictions$fit - 1.96 * predictions$se.fit)
  upper <- stats::plogis(predictions$fit + 1.96 * predictions$se.fit)
  index_mean <- mean(fit, na.rm = TRUE)

  prediction_data |>
    mutate(
      fit = as.numeric(fit),
      lower = as.numeric(lower),
      upper = as.numeric(upper),
      standard_index = fit / index_mean,
      standard_lower = lower / index_mean,
      standard_upper = upper / index_mean,
      median_day_of_season = median_day
    )
}

predict_species_phenology <- function(species_id, model) {
  species_data <- model_data |>
    filter(avibase_id == species_id)

  median_season <- species_data |>
    filter(count > 0) |>
    pull(season) |>
    stats::median(na.rm = TRUE)

  prediction_data <- tibble(
    season = median_season,
    season_centered = season - season_center,
    day_of_season = seq(min(species_data$day_of_season), max(species_data$day_of_season))
  )

  predictions <- stats::predict(model, newdata = prediction_data, type = "link", se.fit = TRUE)
  fit <- stats::plogis(predictions$fit)
  lower <- stats::plogis(predictions$fit - 1.96 * predictions$se.fit)
  upper <- stats::plogis(predictions$fit + 1.96 * predictions$se.fit)
  prediction_data |>
    mutate(
      fit = as.numeric(fit),
      lower = as.numeric(lower),
      upper = as.numeric(upper),
      median_prediction_season = median_season
    )
}

index_predictions <- fitted_models |>
  mutate(predictions = map2(avibase_id, model, predict_species_year_index)) |>
  select(avibase_id, common_name, predictions) |>
  unnest(predictions)

phenology_predictions <- fitted_models |>
  mutate(predictions = map2(avibase_id, model, predict_species_phenology)) |>
  select(avibase_id, common_name, predictions) |>
  unnest(predictions)

annual_summary <- model_data |>
  group_by(avibase_id, common_name, season) |>
  summarise(
    annual_count = sum(count),
    annual_focal_count = sum(total_focal_count),
    raw_annual_proportion = annual_count / annual_focal_count,
    n_positive_days = sum(count > 0),
    .groups = "drop"
  )

write_csv(index_predictions, file.path(summary_dir, "standardized_model_index.csv"), na = "")
write_csv(phenology_predictions, file.path(summary_dir, "phenology_model_predictions.csv"), na = "")
write_csv(annual_summary, file.path(summary_dir, "annual_species_summary.csv"), na = "")

# Figures -----------------------------------------------------------------

species_plot_data <- annual_summary |>
  inner_join(index_predictions, by = c("avibase_id", "common_name", "season"))

proportion_breaks <- function(x) {
  max_x <- max(x[is.finite(x)], na.rm = TRUE)
  candidates <- c(0, 0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 1)
  candidates[candidates <= max(0.1, max_x * 1.05)]
}

plot_species_page <- function(species_id, species_name) {
  year_data <- species_plot_data |>
    filter(avibase_id == species_id)

  daily_data <- model_data |>
    filter(avibase_id == species_id)

  phenology_data <- phenology_predictions |>
    filter(avibase_id == species_id)

  plot_title <- paste0(species_name, " (", species_id, ")")

  year_rate_plot <- ggplot() +
    geom_point(
      data = year_data,
      aes(x = season, y = raw_annual_proportion),
      size = 1.4,
      alpha = 0.65,
      color = "grey25"
    ) +
    geom_ribbon(
      data = year_data,
      aes(x = season, ymin = pmax(lower, 0), ymax = upper),
      fill = "#9ecae1",
      alpha = 0.35
    ) +
    geom_line(
      data = year_data,
      aes(x = season, y = fit),
      color = "#08519c",
      linewidth = 0.75
    ) +
    scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
    labs(
      title = "Year trend: annual raw proportion + model",
      subtitle = "Prediction holds day-of-season at the species median.",
      x = "Season",
      y = "Proportion of focal catch"
    ) +
    theme_minimal(base_size = 10)

  year_index_plot <- ggplot(year_data, aes(x = season, y = standard_index)) +
    geom_ribbon(
      aes(ymin = pmax(standard_lower, 0), ymax = standard_upper),
      fill = "#c7e9c0",
      alpha = 0.45
    ) +
    geom_line(color = "#238b45", linewidth = 0.75) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "grey45") +
    labs(
      title = "Standardized year index",
      subtitle = "Year prediction scaled to mean 1.",
      x = "Season",
      y = "Index"
    ) +
    theme_minimal(base_size = 10)

  phenology_plot <- ggplot() +
    geom_point(
      data = daily_data,
      aes(x = day_of_season, y = proportion),
      size = 0.55,
      alpha = 0.16,
      color = "grey25"
    ) +
    geom_ribbon(
      data = phenology_data,
      aes(x = day_of_season, ymin = pmax(lower, 0), ymax = upper),
      fill = "#fdd0a2",
      alpha = 0.45
    ) +
    geom_line(
      data = phenology_data,
      aes(x = day_of_season, y = fit),
      color = "#d94801",
      linewidth = 0.75
    ) +
    scale_y_continuous(
      limits = c(0, 1),
      breaks = proportion_breaks(c(daily_data$proportion, phenology_data$fit)),
      labels = scales::label_percent(accuracy = 1)
    ) +
    labs(
      title = "Within-season phenology: daily proportions + model",
      subtitle = "Prediction holds season at the species median.",
      x = "Days since 1 October",
      y = "Daily proportion of focal catch"
    ) +
    theme_minimal(base_size = 10)

  catch_plot <- ggplot(year_data, aes(x = season)) +
    geom_col(aes(y = annual_focal_count), fill = "grey78", width = 0.8) +
    geom_line(aes(y = annual_count), color = "#54278f", linewidth = 0.55) +
    geom_point(aes(y = annual_count), color = "#54278f", size = 1.1) +
    labs(
      title = "Annual catch context",
      subtitle = "Bars: focal baseline; line: species count.",
      x = "Season",
      y = "Birds"
    ) +
    theme_minimal(base_size = 10)

  grid::grid.newpage()
  grid::grid.text(
    plot_title,
    x = 0.04,
    y = 0.985,
    just = c("left", "top"),
    gp = grid::gpar(fontsize = 15, fontface = "bold")
  )
  grid::grid.text(
    "These panels estimate relative representation in the Ngulia focal catch, not absolute abundance.",
    x = 0.04,
    y = 0.955,
    just = c("left", "top"),
    gp = grid::gpar(fontsize = 9, col = "grey25")
  )

  print(year_rate_plot, vp = grid::viewport(x = 0.27, y = 0.72, width = 0.48, height = 0.36))
  print(year_index_plot, vp = grid::viewport(x = 0.75, y = 0.72, width = 0.42, height = 0.36))
  print(phenology_plot, vp = grid::viewport(x = 0.27, y = 0.30, width = 0.48, height = 0.38))
  print(catch_plot, vp = grid::viewport(x = 0.75, y = 0.30, width = 0.42, height = 0.38))
}

species_detail_pdf_path <- file.path(figure_dir, "species_composition_trends.pdf")
grDevices::pdf(species_detail_pdf_path, width = 14, height = 10, onefile = TRUE)
walk2(fitted_models$avibase_id, fitted_models$common_name, plot_species_page)
invisible(grDevices::dev.off())

species_figure_paths <- fitted_models |>
  transmute(
    avibase_id,
    common_name,
    pdf_page = row_number(),
    figure_path = file.path(
      "data", "05_derived", "analysis", "composition_trends",
      "figures", "species_composition_trends.pdf"
    )
  )

overview_heatmap <- index_predictions |>
  mutate(common_name = stats::reorder(common_name, standard_index, FUN = mean, na.rm = TRUE)) |>
  ggplot(aes(x = season, y = common_name, fill = standard_index)) +
  geom_tile() +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 1,
    name = "Index"
  ) +
  labs(
    title = "Ngulia standardized composition index by focal species",
    x = "Season",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid = element_blank())

ggsave(
  filename = file.path(figure_dir, "overview_standardized_index_heatmap.pdf"),
  plot = overview_heatmap,
  width = 10,
  height = 7
)

write_csv(species_figure_paths, file.path(summary_dir, "species_figure_paths.csv"), na = "")

cli_alert_success("Wrote figures to {figure_dir}")
cli_alert_success("Wrote model objects to {model_dir}")
cli_alert_success("Wrote summary tables to {summary_dir}")
