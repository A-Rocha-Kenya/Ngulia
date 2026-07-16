library(dplyr)
library(readr)
library(ggplot2)
library(patchwork)
library(cli)
library(scales)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

curated_dir <- paths$curated_dir
figure_dir <- file.path(paths$figures_dir, "ringing_weather_models")

daily_coverage_path <- file.path(curated_dir, "daily_coverage.csv")
model_comparison_path <- file.path(figure_dir, "ringing_model_comparison.png")
djp_predictors_path <- file.path(figure_dir, "ringing_djp_predictors.png")
era5_predictors_path <- file.path(figure_dir, "ringing_era5_predictors.png")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Helpers -----------------------------------------------------------------

score_model_cv <- function(data, formula, label, family, variable_set, folds) {
  pred <- rep(NA_real_, nrow(data))

  for (k in seq_len(max(folds))) {
    fit <- lm(formula, data = data[folds != k, , drop = FALSE])
    pred[folds == k] <- predict(fit, newdata = data[folds == k, , drop = FALSE])
  }

  rmse <- sqrt(mean((data$log_birds - pred)^2))
  r2 <- 1 - sum((data$log_birds - pred)^2) / sum((data$log_birds - mean(data$log_birds))^2)

  tibble(
    model = label,
    family = family,
    variable_set = variable_set,
    rmse = rmse,
    r2 = r2
  )
}

# Read data ---------------------------------------------------------------

cli_h1("QA ringing weather models")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
) |>
  rename(date = ringing_date)

# Prepare data ------------------------------------------------------------

plot_data <- daily_coverage |>
  mutate(
    log_birds = log1p(total_birds_ringed),
    moon_distance = abs(moon_days_from_new_moon),
    djp_mist = case_when(
      djp_weather %in% c("good_mist_2h_plus", "light_or_patchy_mist_1h_plus") ~ "mist",
      djp_weather %in% c("low_cloud", "high_cloud", "clear") ~ "not_mist",
      TRUE ~ NA_character_
    ),
    djp_rain_simple = case_when(
      djp_rain == "none" ~ "none",
      djp_rain == "light_or_heavy_showers" ~ "showers",
      djp_rain == "heavy_rain_1h_plus" ~ "heavy_rain",
      TRUE ~ NA_character_
    ),
    era5_rain_log = log1p(total_precipitation_00_08_mm)
  ) |>
  mutate(
    djp_mist = factor(djp_mist, levels = c("not_mist", "mist")),
    djp_rain_simple = factor(djp_rain_simple, levels = c("none", "showers", "heavy_rain"))
  )

model_data <- plot_data |>
  filter(
    !is.na(log_birds),
    !is.na(moon_distance),
    !is.na(djp_mist),
    !is.na(djp_rain_simple),
    !is.na(mist_score_era5),
    !is.na(era5_rain_log)
  )

set.seed(1)
folds <- sample(rep(1:5, length.out = nrow(model_data)))

# Fit comparison models ---------------------------------------------------

model_scores <- bind_rows(
  score_model_cv(model_data, log_birds ~ moon_distance, "Moon only", "Common", "moon", folds),
  score_model_cv(model_data, log_birds ~ djp_rain_simple, "DJP rain only", "DJP", "rain", folds),
  score_model_cv(model_data, log_birds ~ djp_mist, "DJP mist only", "DJP", "mist", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + djp_rain_simple, "Moon + DJP rain", "DJP", "moon + rain", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + djp_mist, "Moon + DJP mist", "DJP", "moon + mist", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + djp_rain_simple + djp_mist, "Moon + DJP rain + mist", "DJP", "full", folds),
  score_model_cv(model_data, log_birds ~ era5_rain_log, "ERA5 rain only", "ERA5", "rain", folds),
  score_model_cv(model_data, log_birds ~ mist_score_era5, "ERA5 mist only", "ERA5", "mist", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + era5_rain_log, "Moon + ERA5 rain", "ERA5", "moon + rain", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + mist_score_era5, "Moon + ERA5 mist", "ERA5", "moon + mist", folds),
  score_model_cv(model_data, log_birds ~ moon_distance + era5_rain_log + mist_score_era5, "Moon + ERA5 rain + mist", "ERA5", "full", folds)
) |>
  arrange(desc(r2))

model_plot_data <- model_scores |>
  mutate(
    model = factor(model, levels = rev(model)),
    label = paste0("R2=", number(r2, accuracy = 0.01))
  )

# Build figures -----------------------------------------------------------

model_comparison_plot <- ggplot(
  model_plot_data,
  aes(x = r2, y = model, fill = family)
) +
  geom_col(width = 0.72) +
  geom_text(aes(label = label), hjust = -0.1, size = 3.2, color = "#333333") +
  scale_x_continuous(
    limits = c(0, max(model_plot_data$r2) + 0.08),
    labels = label_number(accuracy = 0.01)
  ) +
  scale_fill_manual(values = c(Common = "#9aa0a6", DJP = "#1f5f8b", ERA5 = "#c97b36")) +
  labs(
    title = "How well do moon, rain, and mist predict daily ringing totals?",
    subtitle = "Bars show 5-fold cross-validated R2 for log1p(total_birds_ringed). DJP-coded weather outperforms ERA5-derived weather.",
    x = "Cross-validated R2",
    y = NULL,
    fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

moon_plot_djp <- ggplot(
  model_data,
  aes(x = moon_distance, y = total_birds_ringed)
) +
  geom_point(alpha = 0.18, size = 1.3, color = "#1f5f8b") +
  geom_smooth(method = "loess", se = TRUE, color = "#0f3e5c", linewidth = 0.8) +
  scale_y_sqrt(labels = label_number()) +
  scale_x_continuous(breaks = seq(0, 15, by = 3)) +
  labs(
    title = "Moon",
    subtitle = "Distance from new moon",
    x = "Absolute moon days from new moon",
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11)

djp_rain_plot <- ggplot(
  model_data,
  aes(x = djp_rain_simple, y = total_birds_ringed, fill = djp_rain_simple)
) +
  geom_boxplot(outlier.alpha = 0.2, width = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.15, size = 1, color = "#243746") +
  scale_y_sqrt(labels = label_number()) +
  scale_fill_manual(values = c(none = "#d9d9d9", showers = "#78b7c5", heavy_rain = "#2c7fb8")) +
  labs(
    title = "DJP rain",
    subtitle = "Raw DJP rain coding",
    x = NULL,
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none")

djp_mist_plot <- ggplot(
  model_data,
  aes(x = djp_mist, y = total_birds_ringed, fill = djp_mist)
) +
  geom_boxplot(outlier.alpha = 0.2, width = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.15, size = 1, color = "#243746") +
  scale_y_sqrt(labels = label_number()) +
  scale_fill_manual(values = c(not_mist = "#d9d9d9", mist = "#1f5f8b")) +
  labs(
    title = "DJP mist",
    subtitle = "Strongest single DJP predictor",
    x = NULL,
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none")

djp_predictors_plot <- (moon_plot_djp | djp_rain_plot | djp_mist_plot) +
  plot_annotation(
    title = "Daily ringing totals against DJP-coded moon, rain, and mist",
    subtitle = "Mist has the clearest separation; rain helps; moon contributes but is weaker on its own."
  )

moon_plot_era5 <- ggplot(
  model_data,
  aes(x = moon_distance, y = total_birds_ringed)
) +
  geom_point(alpha = 0.18, size = 1.3, color = "#c97b36") +
  geom_smooth(method = "loess", se = TRUE, color = "#8c5522", linewidth = 0.8) +
  scale_y_sqrt(labels = label_number()) +
  scale_x_continuous(breaks = seq(0, 15, by = 3)) +
  labs(
    title = "Moon",
    subtitle = "Same moon variable as DJP comparison",
    x = "Absolute moon days from new moon",
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11)

era5_rain_plot <- ggplot(
  model_data,
  aes(x = era5_rain_log, y = total_birds_ringed)
) +
  geom_point(alpha = 0.18, size = 1.3, color = "#c97b36") +
  geom_smooth(method = "loess", se = TRUE, color = "#8c5522", linewidth = 0.8) +
  scale_y_sqrt(labels = label_number()) +
  labs(
    title = "ERA5 precipitation",
    subtitle = "log1p(mm) from 00:00-08:00",
    x = "log1p(ERA5 precipitation mm)",
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11)

era5_mist_plot <- ggplot(
  model_data,
  aes(x = mist_score_era5, y = total_birds_ringed)
) +
  geom_point(alpha = 0.18, size = 1.3, color = "#c97b36") +
  geom_smooth(method = "loess", se = TRUE, color = "#8c5522", linewidth = 0.8) +
  scale_y_sqrt(labels = label_number()) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    title = "ERA5 mist score",
    subtitle = "Best single ERA5 predictor",
    x = "mist_score_era5",
    y = "Daily birds ringed"
  ) +
  theme_minimal(base_size = 11)

era5_predictors_plot <- (moon_plot_era5 | era5_rain_plot | era5_mist_plot) +
  plot_annotation(
    title = "Daily ringing totals against moon and ERA5-derived weather",
    subtitle = "ERA5 captures the broad pattern, but with more overlap and weaker prediction than the DJP-coded variables."
  )

# Write output ------------------------------------------------------------

ggsave(model_comparison_path, model_comparison_plot, width = 9, height = 6, dpi = 200)
ggsave(djp_predictors_path, djp_predictors_plot, width = 14, height = 5.5, dpi = 200)
ggsave(era5_predictors_path, era5_predictors_plot, width = 14, height = 5.5, dpi = 200)

cli_alert_success("Wrote ringing weather QA plots to {figure_dir}")
