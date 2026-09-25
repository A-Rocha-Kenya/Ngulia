library(dplyr)
library(readr)
library(ggplot2)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

figure_variant <- Sys.getenv("NGULIA_FIGURE_VARIANT", unset = "paper")
figure_dir <- file.path(paths$qa_output_dir, "daily_context", "figures")
if (figure_variant == "dark_ppt") figure_dir <- file.path(figure_dir, "dark_ppt")

daily_context_path <- file.path(paths$daily_context_intermediate_dir, "daily_context.csv")
moon_png_path <- file.path(figure_dir, "moon_days_comparison.png")
rain_png_path <- file.path(figure_dir, "rain_comparison.png")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

qa_colours <- ngulia_palette(dark = figure_variant == "dark_ppt")

theme_qa <- function(base_size = 11) {
  ngulia_theme(dark = figure_variant == "dark_ppt", base_size = base_size)
}

# Read data ---------------------------------------------------------------

cli_h1("QA daily coverage")

daily_coverage <- read_csv(
  daily_context_path,
  show_col_types = FALSE,
  guess_max = Inf,
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

# Make plots --------------------------------------------------------------

moon_plot <- ggplot(
  moon_comparison,
  aes(x = djp_moon_days_from_new_moon, y = moon_days_from_new_moon)
) +
  geom_abline(intercept = 0, slope = 1, color = qa_colours[["muted"]], linewidth = 0.6) +
  geom_point(alpha = 0.75, color = qa_colours[["blue"]], size = 1.8) +
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
  theme_qa()

rain_plot <- ggplot(
  rain_comparison,
  aes(x = djp_rain, y = total_precipitation_00_08_mm)
) +
  geom_boxplot(fill = qa_colours[["teal"]], outlier.alpha = 0.25) +
  geom_jitter(position = position_jitter(width = 0.15, seed = 91), alpha = 0.2, size = 1, color = qa_colours[["blue"]]) +
  scale_y_sqrt() +
  labs(
    title = "ERA5 precipitation vs DJP rain categories",
    x = "DJP rain",
    y = "ERA5 precipitation 00:00-08:00 (mm)"
  ) +
  theme_qa() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# Write output ------------------------------------------------------------

ggsave(moon_png_path, moon_plot, width = 8, height = 6, dpi = 200, bg = qa_colours[["paper"]])
ggsave(rain_png_path, rain_plot, width = 8, height = 6, dpi = 200, bg = qa_colours[["paper"]])

cli_alert_success("Wrote QA plots to {figure_dir}")
