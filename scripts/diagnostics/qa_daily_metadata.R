library(dplyr)
library(readr)
library(ggplot2)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

curated_dir <- paths$curated_dir
figure_dir <- file.path(paths$figures_dir, "daily_coverage_qa")

daily_coverage_path <- file.path(curated_dir, "daily_coverage.csv")
moon_png_path <- file.path(figure_dir, "moon_days_comparison.png")
rain_png_path <- file.path(figure_dir, "rain_comparison.png")
mist_score_weather_png_path <- file.path(figure_dir, "mist_score_by_weather.png")
mist_score_calibration_png_path <- file.path(figure_dir, "mist_score_calibration.png")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Read data ---------------------------------------------------------------

cli_h1("QA daily coverage")

daily_coverage <- read_csv(
  daily_coverage_path,
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
) |>
  rename(date = ringing_date)

# Build QA data -----------------------------------------------------------

moon_comparison <- daily_coverage |>
  select(date, moon_days_from_new_moon, djp_moon_days_from_new_moon) |>
  filter(!is.na(djp_moon_days_from_new_moon)) |>
  mutate(moon_delta = moon_days_from_new_moon - djp_moon_days_from_new_moon)

moon_summary <- moon_comparison |>
  summarise(
    n = n(),
    n_exact = sum(moon_delta == 0),
    mean_abs_delta = mean(abs(moon_delta))
  )

rain_comparison <- daily_coverage |>
  filter(!is.na(total_precipitation_00_08_mm)) |>
  mutate(
    djp_rain = factor(
      djp_rain,
      levels = c(
        "none",
        "light_or_heavy_showers",
        "heavy_rain_1h_plus",
        "rain_noted_in_weather_code",
        "unknown"
      )
    )
  ) |>
  filter(!is.na(djp_rain))

weather_comparison <- daily_coverage |>
  filter(!is.na(mist_score_era5)) |>
  mutate(
    djp_weather = factor(
      djp_weather,
      levels = c(
        "good_mist_2h_plus",
        "light_or_patchy_mist_1h_plus",
        "low_cloud",
        "high_cloud",
        "clear",
        "unknown"
      )
    )
  ) |>
  filter(!is.na(djp_weather)) |>
  filter(djp_weather != "unknown")

mist_binary_comparison <- daily_coverage |>
  filter(!is.na(mist_score_era5)) |>
  mutate(
    djp_mist_binary = case_when(
      djp_weather %in% c("good_mist_2h_plus", "light_or_patchy_mist_1h_plus") ~ "mist",
      djp_weather %in% c("low_cloud", "high_cloud", "clear") ~ "not_mist",
      TRUE ~ NA_character_
    ),
    djp_mist_binary = factor(djp_mist_binary, levels = c("mist", "not_mist"))
  ) |>
  filter(!is.na(djp_mist_binary))

mist_score_summary <- mist_binary_comparison |>
  summarise(
    n = n(),
    mean_score_mist = mean(mist_score_era5[djp_mist_binary == "mist"]),
    mean_score_not_mist = mean(mist_score_era5[djp_mist_binary == "not_mist"])
  )

mist_score_calibration <- mist_binary_comparison |>
  mutate(score_bin = cut(
    mist_score_era5,
    breaks = seq(0, 1, by = 0.1),
    include.lowest = TRUE,
    right = TRUE
  )) |>
  group_by(score_bin) |>
  summarise(
    n_days = n(),
    score_midpoint = mean(mist_score_era5),
    observed_mist_rate = mean(djp_mist_binary == "mist"),
    se = sqrt(observed_mist_rate * (1 - observed_mist_rate) / n_days),
    ci_low = pmax(0, observed_mist_rate - 1.96 * se),
    ci_high = pmin(1, observed_mist_rate + 1.96 * se),
    label_y = pmin(0.98, observed_mist_rate + 0.045),
    .groups = "drop"
  ) |>
  filter(!is.na(score_bin))

# Make plots --------------------------------------------------------------

moon_plot <- ggplot(
  moon_comparison,
  aes(x = djp_moon_days_from_new_moon, y = moon_days_from_new_moon)
) +
  geom_abline(intercept = 0, slope = 1, color = "grey60", linewidth = 0.6) +
  geom_point(alpha = 0.75, color = "#1f5f8b", size = 1.8) +
  scale_x_continuous(breaks = seq(-15, 15, by = 5)) +
  scale_y_continuous(breaks = seq(-15, 15, by = 5)) +
  coord_equal() +
  labs(
    title = "Computed moon days vs DJP moon days",
    subtitle = paste0(
      "n = ", moon_summary$n,
      "; exact matches = ", moon_summary$n_exact,
      "; mean absolute difference = ", round(moon_summary$mean_abs_delta, 2), " days"
    ),
    x = "DJP moon days from new moon",
    y = "Computed moon days from new moon"
  ) +
  theme_minimal(base_size = 12)

rain_plot <- ggplot(
  rain_comparison,
  aes(x = djp_rain, y = total_precipitation_00_08_mm)
) +
  geom_boxplot(fill = "#78b7c5", outlier.alpha = 0.25) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1, color = "#1f5f8b") +
  scale_y_sqrt() +
  labs(
    title = "ERA5 precipitation vs DJP rain categories",
    x = "DJP rain",
    y = "ERA5 precipitation 00:00-08:00 (mm)"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

mist_score_weather_plot <- ggplot(
  weather_comparison,
  aes(x = djp_weather, y = mist_score_era5)
) +
  geom_boxplot(fill = "#78b7c5", outlier.alpha = 0.2) +
  geom_jitter(width = 0.15, alpha = 0.2, size = 1, color = "#1f5f8b") +
  coord_cartesian(ylim = c(0.15, 0.95)) +
  labs(
    title = "ERA5 mist score by DJP weather category",
    subtitle = paste0(
      "Mist days score higher on average (",
      round(mist_score_summary$mean_score_mist, 2),
      ") than non-mist days (",
      round(mist_score_summary$mean_score_not_mist, 2),
      "); overlap shows imperfect separation"
    ),
    x = "DJP weather",
    y = "ERA5 mist score"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

mist_score_calibration_plot <- ggplot(
  mist_score_calibration,
  aes(x = score_midpoint, y = observed_mist_rate)
) +
  geom_abline(intercept = 0, slope = 1, color = "grey70", linetype = "dashed") +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.015, color = "#1f5f8b") +
  geom_point(aes(size = n_days), color = "#1f5f8b", alpha = 0.9) +
  geom_text(aes(y = label_y, label = n_days), size = 3, color = "#444444") +
  scale_x_continuous(limits = c(0, 1)) +
  scale_y_continuous(limits = c(0, 1), labels = scales::percent_format(accuracy = 1)) +
  scale_size_continuous(range = c(2.5, 7), guide = "none") +
  labs(
    title = "Observed DJP mist rate by ERA5 mist score bin",
    subtitle = "Points on the dashed line would indicate perfect calibration; labels show number of days per bin",
    x = "Mean ERA5 mist score within bin",
    y = "Observed DJP mist frequency"
  ) +
  theme_minimal(base_size = 12)

# Write output ------------------------------------------------------------

ggsave(moon_png_path, moon_plot, width = 8, height = 6, dpi = 200)
ggsave(rain_png_path, rain_plot, width = 8, height = 6, dpi = 200)
ggsave(mist_score_weather_png_path, mist_score_weather_plot, width = 8, height = 6, dpi = 200)
ggsave(mist_score_calibration_png_path, mist_score_calibration_plot, width = 8, height = 6, dpi = 200)

cli_alert_success("Wrote QA plots to {figure_dir}")
