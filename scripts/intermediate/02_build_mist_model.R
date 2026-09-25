library(dplyr)
library(readr)
library(tibble)
library(tidyr)
library(nnet)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- here::here()
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)
source(file.path(project_dir, "scripts", "helpers", "mist_state.R"))

daily_context_path <- file.path(paths$daily_context_intermediate_dir, "daily_context.csv")
mist_dir <- paths$mist_intermediate_dir

dir.create(mist_dir, recursive = TRUE, showWarnings = FALSE)

# Helpers -----------------------------------------------------------------

mist_levels <- c("none", "light_patchy", "good")

predict_probabilities <- function(model, data) {
  probability <- predict(model, newdata = data, type = "probs")
  probability <- as.matrix(probability)
  probability[, mist_levels, drop = FALSE]
}

score_multiclass <- function(observed, probability) {
  observed_index <- match(observed, mist_levels)
  observed_matrix <- diag(length(mist_levels))[observed_index, , drop = FALSE]
  tibble(
    log_loss = -mean(log(pmax(probability[cbind(seq_along(observed_index), observed_index)], 1e-12))),
    brier_score = mean(rowSums((observed_matrix - probability)^2)),
    accuracy = mean(mist_levels[max.col(probability)] == observed)
  )
}

cross_validate_mist_model <- function(data, formula, folds) {
  probability <- matrix(NA_real_, nrow(data), length(mist_levels), dimnames = list(NULL, mist_levels))

  for (fold in sort(unique(folds))) {
    fit <- multinom(formula, data = data[folds != fold, ], trace = FALSE)
    probability[folds == fold, ] <- predict_probabilities(fit, data[folds == fold, ])
  }

  bind_cols(as_tibble(probability, .name_repair = "minimal"), score_multiclass(data$mist_state, probability))
}

# Read and prepare observed mist states ----------------------------------

cli_h1("Build the unified observed/ERA5 mist model")

daily_context <- read_csv(
  daily_context_path,
  show_col_types = FALSE,
  guess_max = Inf,
  col_types = cols(ringing_date = col_date())
) |>
  mutate(
    cloud_base_height_km = cloud_base_height_mean_m / 1000,
    cloud_base_height_min_km = cloud_base_height_min_m / 1000,
    mist_state = factor(mist_observation, levels = mist_levels)
  )

model_predictors <- c(
  "total_cloud_cover_mean", "cloud_base_height_km", "cloud_base_height_min_km",
  "relative_humidity_mean_pct", "relative_humidity_max_pct", "near_saturated_hours",
  "temperature_2m_mean_c", "dewpoint_depression_min_c", "wind_u_10m_mean_ms"
)

mist_training_data <- daily_context |>
  filter(
    mist_observation %in% mist_levels,
    complete.cases(across(all_of(model_predictors)))
  )

# Select the ERA5 calibration with seasons held out ----------------------

set.seed(91)
season_folds <- tibble(season = sort(unique(mist_training_data$season))) |>
  mutate(fold = sample(rep(1:5, length.out = n())))

mist_training_data <- mist_training_data |>
  left_join(season_folds, by = "season")

model_formulas <- list(
  "Mean humidity + cloud" = mist_state ~ total_cloud_cover_mean + cloud_base_height_km + relative_humidity_mean_pct,
  "Mean humidity + cloud + easterly flow" = mist_state ~ total_cloud_cover_mean + cloud_base_height_km + relative_humidity_mean_pct + wind_u_10m_mean_ms,
  "Mean humidity + cloud + wind + temperature" = mist_state ~ total_cloud_cover_mean + cloud_base_height_km + relative_humidity_mean_pct + wind_u_10m_mean_ms + temperature_2m_mean_c,
  "Dew-point depression + cloud + wind" = mist_state ~ total_cloud_cover_mean + cloud_base_height_min_km + dewpoint_depression_min_c + wind_u_10m_mean_ms,
  "Night-time humidity maximum + cloud + wind" = mist_state ~ total_cloud_cover_mean + cloud_base_height_min_km + relative_humidity_max_pct + wind_u_10m_mean_ms,
  "Near-saturated hours + cloud + wind" = mist_state ~ total_cloud_cover_mean + cloud_base_height_min_km + near_saturated_hours + wind_u_10m_mean_ms
)

candidate_validation <- lapply(model_formulas, function(formula) {
  cross_validate_mist_model(mist_training_data, formula, mist_training_data$fold)
})

validation_results <- lapply(names(candidate_validation), function(model_name) {
  validation <- candidate_validation[[model_name]]
  tibble(
    model = model_name,
    log_loss = validation$log_loss[[1]],
    brier_score = validation$brier_score[[1]],
    accuracy = validation$accuracy[[1]]
  )
}) |>
  bind_rows()

selected_model_name <- validation_results |>
  slice_min(log_loss, n = 1, with_ties = FALSE) |>
  pull(model)

mist_model <- multinom(model_formulas[[selected_model_name]], data = mist_training_data, trace = FALSE, Hess = TRUE)
training_validation <- candidate_validation[[selected_model_name]]

# Combine direct observations with modeled state probabilities -----------

prediction_input <- daily_context |>
  filter(if_all(all_of(setdiff(all.vars(formula(mist_model)), "mist_state")), ~ !is.na(.x)))

probability <- predict_probabilities(mist_model, prediction_input)
probability <- constrain_mist_probabilities(probability, prediction_input$mist_observation)

mist_probabilities <- prediction_input |>
  transmute(ringing_date, season) |>
  bind_cols(
    tibble(
      mist_probability_none = probability[, "none"],
      mist_probability_light_patchy = probability[, "light_patchy"],
      mist_probability_good = probability[, "good"]
    )
  ) |>
  mutate(mist_most_likely = mist_levels[max.col(probability)], mist_model = selected_model_name)

validation_predictions <- mist_training_data |>
  transmute(ringing_date, season, djp_weather, mist_observation, validation_fold = fold) |>
  bind_cols(
    training_validation |>
      select(all_of(mist_levels)) |>
      setNames(c("predicted_none", "predicted_light_patchy", "predicted_good"))
  )

model_summary <- summary(mist_model)
model_coefficients <- as.data.frame(as.table(model_summary$coefficients)) |>
  as_tibble() |>
  rename(mist_state = Var1, term = Var2, estimate = Freq) |>
  left_join(
    as.data.frame(as.table(model_summary$standard.errors)) |>
      as_tibble() |>
      rename(mist_state = Var1, term = Var2, standard_error = Freq),
    by = c("mist_state", "term")
  )

# Write outputs -----------------------------------------------------------

saveRDS(mist_model, file.path(mist_dir, "mist_model.rds"))
write_csv(mist_probabilities, file.path(mist_dir, "mist_state_probabilities.csv"))
write_csv(
  validation_results |>
    mutate(selected = model == selected_model_name),
  file.path(mist_dir, "mist_model_validation.csv")
)
write_csv(model_coefficients, file.path(mist_dir, "mist_model_coefficients.csv"))
write_csv(validation_predictions, file.path(mist_dir, "mist_model_validation_predictions.csv"))

cli_alert_success("Wrote unified mist model and state probabilities to {mist_dir}")
