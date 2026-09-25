library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)
library(htmltools)
library(nnet)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "plot_style.R"))
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

mist_dir <- paths$mist_intermediate_dir
qa_dir <- file.path(paths$qa_output_dir, "mist_model")
figure_dir <- ngulia_figure_dir(file.path(qa_dir, "figures"))
table_dir <- file.path(qa_dir, "tables")

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

# Read unified mist-model outputs ----------------------------------------

cli_h1("Validate the unified observed/ERA5 mist model")

model_validation <- read_csv(file.path(mist_dir, "mist_model_validation.csv"), show_col_types = FALSE)
model_coefficients <- read_csv(file.path(mist_dir, "mist_model_coefficients.csv"), show_col_types = FALSE)
mist_model <- readRDS(file.path(mist_dir, "mist_model.rds"))
validation_predictions <- read_csv(
  file.path(mist_dir, "mist_model_validation_predictions.csv"),
  show_col_types = FALSE,
  col_types = cols(ringing_date = col_date())
)
daily_context <- read_csv(
  file.path(paths$daily_context_intermediate_dir, "daily_context.csv"),
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date())
) |>
  mutate(
    cloud_base_height_km = cloud_base_height_mean_m / 1000,
    cloud_base_height_min_km = cloud_base_height_min_m / 1000
  )

# Read the original DJP weather symbols so the report documents the
# source-to-analysis mapping rather than only showing the fitted model.
raw_djp_metadata <- read_csv(
  file.path(paths$daily_counts_intermediate_dir, "djp_daily_metadata.csv"),
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(date = col_date())
)

mist_levels <- c("none", "light_patchy", "good")
mist_colours <- c(none = "#7C878C", light_patchy = "#A64078", good = "#007C91")
candidate_variables <- tibble::tribble(
  ~variable, ~label,
  "total_cloud_cover_mean", "Mean total cloud cover (fraction)",
  "cloud_base_height_km", "Mean cloud-base height (km)",
  "cloud_base_height_min_km", "Minimum cloud-base height (km)",
  "relative_humidity_mean_pct", "Mean relative humidity (%)",
  "relative_humidity_max_pct", "Maximum relative humidity (%)",
  "near_saturated_hours", "Near-saturated hours (RH ≥95%)",
  "temperature_2m_mean_c", "Mean 2 m temperature (°C)",
  "dewpoint_depression_min_c", "Minimum dew-point depression (°C)",
  "wind_u_10m_mean_ms", "Mean easterly wind component (m/s)"
)

raw_weather_mapping <- raw_djp_metadata |>
  count(weather, name = "n") |>
  mutate(
    raw_symbol = coalesce(weather, "<blank>"),
    mist_mapping = case_when(
      weather %in% c("M", "MR") ~ "good mist",
      weather %in% c("m", "mr") ~ "light/patchy mist",
      weather %in% c("l", "c", "o") ~ "no mist recorded",
      weather %in% c("?", "X") | is.na(weather) ~ "unknown",
      TRUE ~ "unmapped/unknown"
    ),
    rain_information = case_when(
      weather %in% c("MR", "mr") ~ "rain suffix also present",
      TRUE ~ "none in weather symbol"
    )
  ) |>
  select(raw_symbol, n, mist_mapping, rain_information) |>
  arrange(desc(n), raw_symbol)

raw_rain_mapping <- raw_djp_metadata |>
  count(rain, name = "n") |>
  mutate(
    raw_symbol = coalesce(rain, "<blank>"),
    rain_mapping = case_when(
      rain == "R" ~ "heavy rain (1 h+)",
      rain == "r" ~ "light or heavy showers",
      is.na(rain) ~ "no separate rain symbol recorded",
      TRUE ~ "unmapped/unknown"
    )
  ) |>
  select(raw_symbol, n, rain_mapping) |>
  arrange(desc(n), raw_symbol)

canonical_weather_counts <- daily_context |>
  count(mist_observation, name = "n") |>
  mutate(category = coalesce(mist_observation, "<missing>")) |>
  select(category, n)

canonical_rain_counts <- daily_context |>
  count(rain_observed, name = "n") |>
  mutate(category = coalesce(rain_observed, "<missing>")) |>
  select(category, n)

training_data <- daily_context |>
  filter(
    mist_observation %in% mist_levels,
    complete.cases(across(all_of(candidate_variables$variable)))
  ) |>
  mutate(mist_observation = factor(mist_observation, levels = mist_levels))

# Summarize performance and classification -------------------------------

performance_data <- model_validation |>
  pivot_longer(c(log_loss, accuracy), names_to = "metric", values_to = "value") |>
  mutate(
    metric = recode(metric, log_loss = "Held-out log loss (lower is better)", accuracy = "Held-out classification accuracy"),
    model = factor(model, levels = model_validation |> arrange(log_loss) |> pull(model))
  )

performance_plot <- ggplot(performance_data, aes(x = value, y = model, colour = selected)) +
  geom_point(size = 3) +
  geom_text(aes(label = sprintf("%.3f", value)), hjust = -0.55, colour = "#33434A", size = 3.2) +
  facet_wrap(vars(metric), scales = "free_x", ncol = 1) +
  scale_colour_manual(values = c(`TRUE` = "#007C91", `FALSE` = "#7C878C"), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0.08, 0.18))) +
  labs(title = "Season-blocked mist-model comparison", subtitle = "Log loss determines selection; only the two clearest validation metrics are shown.", x = NULL, y = NULL) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")

predicted_state <- c("none", "light_patchy", "good")[max.col(as.matrix(
  validation_predictions |> select(starts_with("predicted_"))
))]

confusion_data <- validation_predictions |>
  mutate(
    predicted = predicted_state,
    mist_observation = factor(mist_observation, levels = c("none", "light_patchy", "good")),
    predicted = factor(predicted, levels = c("none", "light_patchy", "good"))
  ) |>
  count(mist_observation, predicted) |>
  group_by(mist_observation) |>
  mutate(fraction = n / sum(n)) |>
  ungroup()

confusion_plot <- ggplot(confusion_data, aes(x = predicted, y = mist_observation, fill = fraction)) +
  geom_tile(colour = "white", linewidth = 1) +
  geom_text(aes(label = paste0(n, "\n", percent(fraction, accuracy = 1))), colour = "white", fontface = "bold") +
  scale_fill_gradient(low = "#BFD8DF", high = ngulia_colours[["blue"]], labels = label_percent(), limits = c(0, 1)) +
  labs(
    title = "Held-out mist-state classification",
    subtitle = "Rows sum to 100%; predictions come from seasons excluded during calibration.",
    x = "Most likely predicted state",
    y = "Observed state",
    fill = "Row share"
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid = element_blank(), plot.title.position = "plot")

# Describe the ERA5 links and coverage -----------------------------------

era5_association_data <- bind_rows(lapply(seq_len(nrow(candidate_variables)), function(i) {
  variable <- candidate_variables$variable[[i]]
  training_data |>
    mutate(bin = ntile(.data[[variable]], 8)) |>
    group_by(bin, mist_observation) |>
    summarise(value = mean(.data[[variable]]), n = n(), .groups = "drop") |>
    complete(bin, mist_observation = factor(mist_levels, levels = mist_levels), fill = list(n = 0)) |>
    group_by(bin) |>
    mutate(fraction = n / sum(n)) |>
    ungroup() |>
    mutate(
      variable = candidate_variables$label[[i]],
      selected = candidate_variables$variable[[i]] %in% setdiff(all.vars(formula(mist_model)), "mist_state")
    )
})) |>
  mutate(variable = factor(variable, levels = candidate_variables$label))

era5_association_plot <- ggplot(era5_association_data, aes(value, fraction, colour = mist_observation)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  facet_wrap(vars(variable), scales = "free_x", ncol = 2) +
  scale_colour_manual(
    values = mist_colours,
    labels = c(none = "No mist", light_patchy = "Light/patchy mist", good = "Good mist")
  ) +
  scale_y_continuous(labels = label_percent(), limits = c(0, 1)) +
  labs(
    title = "Observed mist states across each candidate ERA5 variable",
    subtitle = "Each point summarizes one ninth of the observed-mist dates. The final model uses the retained weather representation only.",
    x = NULL,
    y = "Share of observed dates",
    colour = NULL
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "top", plot.title.position = "plot")

selected_variables <- candidate_variables |>
  filter(variable %in% setdiff(all.vars(formula(mist_model)), "mist_state"))

reference_data <- training_data[rep(1, 100), ]
model_variables <- setdiff(all.vars(formula(mist_model)), "mist_state")
for (variable in model_variables) {
  reference_data[[variable]] <- median(training_data[[variable]])
}

selected_effect_data <- bind_rows(lapply(seq_len(nrow(selected_variables)), function(i) {
  variable <- selected_variables$variable[[i]]
  values <- seq(
    quantile(training_data[[variable]], 0.02),
    quantile(training_data[[variable]], 0.98),
    length.out = 100
  )
  prediction_data <- reference_data
  prediction_data[[variable]] <- values
  probability <- as.matrix(predict(mist_model, newdata = prediction_data, type = "probs"))
  tibble(value = values) |>
    bind_cols(as_tibble(probability[, mist_levels, drop = FALSE])) |>
    pivot_longer(-value, names_to = "mist_state", values_to = "probability") |>
    mutate(variable = selected_variables$label[[i]])
})) |>
  mutate(variable = factor(variable, levels = selected_variables$label))

selected_effect_plot <- ggplot(selected_effect_data, aes(value, probability, colour = mist_state)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(vars(variable), scales = "free_x", ncol = 2) +
  scale_colour_manual(
    values = mist_colours,
    labels = c(none = "No mist", light_patchy = "Light/patchy mist", good = "Good mist")
  ) +
  scale_y_continuous(labels = label_percent(), limits = c(0, 1)) +
  labs(
    title = "Selected ERA5 predictors in the fitted mist model",
    subtitle = "One predictor changes at a time; the other selected predictors are held at their observed median.",
    x = NULL,
    y = "Model probability",
    colour = NULL
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "top", plot.title.position = "plot")

coverage_data <- daily_context |>
  group_by(season) |>
  summarise(
    daily_context_dates = n(),
    complete_era5_dates = sum(complete.cases(across(all_of(candidate_variables$variable)))),
    observed_mist_dates = sum(mist_observation %in% mist_levels),
    model_training_dates = sum(
      mist_observation %in% mist_levels & complete.cases(across(all_of(candidate_variables$variable)))
    ),
    .groups = "drop"
  ) |>
  pivot_longer(-season, names_to = "source", values_to = "dates") |>
  mutate(
    source = factor(source,
      levels = c("daily_context_dates", "complete_era5_dates", "observed_mist_dates", "model_training_dates"),
      labels = c("Daily context", "Complete candidate ERA5", "Exact observed mist", "Mist-model training")
    )
  )

mist_observation_coverage <- daily_context |>
  filter(mist_observation %in% mist_levels) |>
  mutate(
    season_day = as.integer(ringing_date - as.Date(paste0(season, "-10-19"))),
    mist_observation = factor(mist_observation, levels = mist_levels)
  )

coverage_plot <- ggplot(mist_observation_coverage, aes(season_day, season, fill = mist_observation)) +
  geom_tile(width = 0.95, height = 0.85) +
  scale_fill_manual(values = mist_colours, labels = c(none = "No mist", light_patchy = "Light/patchy mist", good = "Good mist")) +
  scale_x_continuous(breaks = c(1, 32, 62, 93), labels = c("20 Oct", "20 Nov", "20 Dec", "20 Jan")) +
  scale_y_continuous(breaks = seq(1970, 2020, 10)) +
  labs(
    title = "Exact mist observations by date and season",
    subtitle = "Each tile is a date with a recorded mist state; blank space means no exact mist observation. Notes are sparse after 2014 and absent in 2017–2022.",
    x = "Date within ringing season",
    y = "Season",
    fill = NULL
  ) +
  ngulia_theme(base_size = 11) +
  theme(panel.grid = element_blank(), legend.position = "top", plot.title.position = "plot")

coverage_table <- coverage_data |>
  pivot_wider(names_from = source, values_from = dates)

input_summary <- training_data |>
  summarise(across(all_of(candidate_variables$variable), list(min = min, median = median, max = max))) |>
  pivot_longer(everything(), names_to = c("variable", ".value"), names_pattern = "(.*)_(min|median|max)") |>
  left_join(candidate_variables, by = "variable") |>
  transmute(
    selected = variable %in% setdiff(all.vars(formula(mist_model)), "mist_state"),
    variable = label,
    observed_range = paste0(signif(min, 3), " to ", signif(max, 3)),
    median = signif(median, 3)
  )

# Write outputs -----------------------------------------------------------

write_csv(model_validation, file.path(table_dir, "mist_model_cross_validation.csv"))
write_csv(model_coefficients, file.path(table_dir, "mist_model_coefficients.csv"))
write_csv(validation_predictions, file.path(table_dir, "mist_model_validation_predictions.csv"))
write_csv(confusion_data, file.path(table_dir, "mist_model_confusion.csv"))
write_csv(coverage_table, file.path(table_dir, "mist_model_coverage_by_season.csv"))
write_csv(input_summary, file.path(table_dir, "mist_model_predictor_summary.csv"))
ggsave(file.path(figure_dir, "01_mist_model_performance.png"), performance_plot, width = 12, height = 6.5, dpi = 220)
ggsave(file.path(figure_dir, "02_mist_model_confusion.png"), confusion_plot, width = 8, height = 6.5, dpi = 220)
ggsave(file.path(figure_dir, "03_era5_mist_associations.png"), era5_association_plot, width = 12, height = 11, dpi = 220)
ggsave(file.path(figure_dir, "04_selected_era5_mist_effects.png"), selected_effect_plot, width = 12, height = 8, dpi = 220)
ggsave(file.path(figure_dir, "05_mist_model_coverage.png"), coverage_plot, width = 12, height = 9, dpi = 220)

# Build an explanatory HTML report ---------------------------------------

html_table <- function(data) {
  tags$table(
    tags$thead(tags$tr(lapply(names(data), tags$th))),
    tags$tbody(lapply(seq_len(nrow(data)), function(i) {
      tags$tr(lapply(data, function(column) tags$td(as.character(column[[i]]))))
    }))
  )
}

selected_model <- model_validation |>
  filter(selected)
selected_predictors <- selected_variables |>
  pull(label) |>
  paste(collapse = ", ")
model_selection_table <- model_validation |>
  transmute(
    Model = model,
    `Held-out log loss` = sprintf("%.3f", log_loss),
    `Classification accuracy` = percent(accuracy, accuracy = 0.1),
    Selected = if_else(selected, "Yes", "No")
  )
coverage_summary <- daily_context |>
  summarise(
    first = min(ringing_date),
    last = max(ringing_date),
    exact_mist = sum(mist_observation %in% mist_levels),
    training = sum(mist_observation %in% mist_levels & complete.cases(across(all_of(candidate_variables$variable))))
  )

report <- tags$html(
  tags$head(
    tags$meta(charset = "utf-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$title("Ngulia mist-model calibration"),
    tags$style(HTML(paste(readLines(file.path(project_dir, "assets", "report.css")), collapse = "\n")))
  ),
  tags$body(
    tags$h1("How mist is reconstructed at Ngulia"),
    tags$p(class = "lede", "A three-state calibration connects recorded mist notes to ERA5 weather, then supplies probabilities for dates without a direct note."),
    tags$div(class = "note", tags$b("States: "), "no mist, light/patchy mist, and good mist. Directly recorded exact states remain fixed; the model is used to describe uncertainty only where a state is not recorded."),

    tags$h2("1. Data coverage"),
    tags$p(paste0(
      "The daily context spans ", format(coverage_summary$first, "%d %B %Y"), " to ", format(coverage_summary$last, "%d %B %Y"),
      ". It contains ", coverage_summary$exact_mist, " dates with an exact mist state, of which ", coverage_summary$training,
      " have all candidate ERA5 predictors. ERA5 coverage extends across the record, but the direct mist notes are primarily historical."
    )),
    tags$img(class = "figure wide", src = "figures/05_mist_model_coverage.png", alt = "Exact mist observations by date within ringing season and season"),

    tags$h2("2. From the original weather symbols to the analysis variables"),
    tags$p("The historical DJP workbook records weather and rain separately, with a small symbol vocabulary. Mist is not inferred from rain: the weather symbol supplies the mist evidence, while the rain field is retained as a separate covariate. Combined symbols such as MR or mr carry both pieces of information."),
    tags$h3("Original weather symbols"),
    html_table(raw_weather_mapping |>
      rename(`Raw weather symbol` = raw_symbol, `Dates` = n, `Mist interpretation` = mist_mapping, `Rain information` = rain_information)
    ),
    tags$h3("Original rain field"),
    html_table(raw_rain_mapping |>
      rename(`Raw rain symbol` = raw_symbol, `Dates` = n, `Rain interpretation` = rain_mapping)
    ),
    tags$p("After source decoding and reviewed corrections, the canonical daily fields contain the following categories. The additional present_unspecified category comes from dated narrative evidence that confirms mist but does not specify its intensity; it is constrained to the two mist-present states and is not used as a fourth calibration class."),
    tags$div(class = "two-column",
      tags$div(tags$h3("Canonical mist field"), html_table(canonical_weather_counts |> rename(Category = category, Dates = n))),
      tags$div(tags$h3("Canonical rain field"), html_table(canonical_rain_counts |> rename(Category = category, Dates = n)))
    ),
    tags$h3("Why three mist states?"),
    tags$ul(
      tags$li("The source notation itself distinguishes uppercase M (good/longer mist) from lowercase m (light or patchy mist), while l, c and o indicate low cloud, high cloud and clear conditions rather than a graded mist scale."),
      tags$li("These two observed mist intensities plus no mist are therefore the finest consistently supported categories in the original daily coding. Splitting them further would mostly create unsupported or subjective classes."),
      tags$li("Narrative notes sometimes say that mist was present without describing intensity. Those dates remain uncertain between light/patchy and good mist instead of being forced into a new category."),
      tags$li("Rain is deliberately not folded into mist: R/r are retained as separate rain categories because rain and mist can co-occur and have different effects on net operation and capture.")
    ),

    tags$h2("3. Model and predictor selection"),
    tags$div(class = "equation", HTML("mist state ~ cloud cover + cloud-base height + relative humidity + easterly wind")),
    tags$p(paste0(
      "Six deliberately small multinomial models were evaluated by holding out entire seasons. The selected ", selected_model$model,
      " model has held-out log loss ", sprintf("%.3f", selected_model$log_loss), ", Brier score ", sprintf("%.3f", selected_model$brier_score),
      ", and classification accuracy ", percent(selected_model$accuracy, accuracy = 0.1), "."
    )),
    tags$p(paste0("Selected predictors: ", selected_predictors, ". Temperature, dew-point depression, humidity maxima, near-saturated hours, and minimum cloud-base height were tested in alternative compact models; none improved held-out log loss.")),
    tags$img(class = "figure wide", src = "figures/01_mist_model_performance.png", alt = "Season-blocked performance of candidate mist models"),
    html_table(model_selection_table),

    tags$h2("4. What the ERA5 variables say about mist"),
    tags$p("This descriptive view uses the observed mist notes only. Each panel divides its predictor into eight equally populated ranges and shows the state mix within each range. It includes both the retained mean-weather variables and the alternative hourly summaries."),
    tags$img(class = "figure wide", src = "figures/03_era5_mist_associations.png", alt = "Observed mist-state shares across the candidate ERA5 predictors"),
    tags$p("The next figure isolates the fitted association for each retained predictor. It changes one variable while holding the other retained variables at their observed medians; it should therefore be read as an adjusted model description, not as a causal effect."),
    tags$img(class = "figure wide", src = "figures/04_selected_era5_mist_effects.png", alt = "Fitted mist probabilities across selected ERA5 predictors"),
    html_table(input_summary |>
      mutate(selected = if_else(selected, "Yes", "No")) |>
      rename(Predictor = variable, Selected = selected, `Observed range` = observed_range, Median = median)
    ),

    tags$h2("5. Validation"),
    tags$p("For each validation fold, all dates from one group of seasons were predicted by a model trained on the remaining seasons. This prevents a model from benefiting simply because adjacent dates from the same season have similar weather notes."),
    tags$img(class = "figure", src = "figures/02_mist_model_confusion.png", alt = "Held-out confusion matrix for mist-state classification"),
    tags$p("The most likely class is a convenient summary only. Downstream analyses retain the full three-state probabilities, so ambiguous weather conditions are not treated as certain observations."),

    tags$h2("Outputs"),
    tags$p("Tables: ",
      tags$a(href = "tables/mist_model_cross_validation.csv", "cross-validation"), " · ",
      tags$a(href = "tables/mist_model_coefficients.csv", "coefficients"), " · ",
      tags$a(href = "tables/mist_model_coverage_by_season.csv", "coverage"), " · ",
      tags$a(href = "tables/mist_model_predictor_summary.csv", "predictor ranges"), " · ",
      tags$a(href = "tables/mist_model_validation_predictions.csv", "held-out predictions")
    )
  )
)

rendered_report <- renderTags(report)
report_html <- sub(
  "<html>",
  paste0("<!doctype html>\n<html>\n<head>\n", rendered_report$head, "\n</head>"),
  rendered_report$html,
  fixed = TRUE
)
writeLines(report_html, file.path(qa_dir, "mist_model_report.html"))

cli_alert_success("Wrote unified mist-model QA results and report to {qa_dir}")
