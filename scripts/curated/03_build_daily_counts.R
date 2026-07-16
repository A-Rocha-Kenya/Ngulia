library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

curated_dir <- paths$curated_dir
daily_counts_dir <- paths$daily_counts_intermediate_dir
ring_events_config_dir <- paths$ring_events_config_dir
dir.create(curated_dir, recursive = TRUE, showWarnings = FALSE)

ring_events_path <- file.path(curated_dir, "ring_events.csv")
djp_daily_counts_path <- file.path(daily_counts_dir, "djp_daily_counts.csv")
species_reference_path <- file.path(
  ring_events_config_dir,
  "species_reference.csv"
)
taxonomy_path <- file.path(
  paths$reference_dir,
  "taxonomy",
  "ebird_clements_2025_integrated_checklist.csv"
)
daily_counts_output_path <- file.path(curated_dir, "daily_counts.csv")

source(file.path(project_dir, "scripts", "helpers", "ring_event_helpers.R"))

# Set source preference ---------------------------------------------------

# Source selection is currently resolved at the season level, not day by day.
# If a season has any DJP daily-summary rows, those rows are taken as the
# preferred species-day count source for that whole season.
preferred_daily_count_source <- "djp_daily_summary"
daily_count_source_priority <- c(
  djp_daily_summary = 1L,
  ring_events = 2L
)

# Read data ---------------------------------------------------------------

cli_h1("Build consolidated daily counts")

taxonomy_reference <- if (file.exists(taxonomy_path)) {
  read_csv(
    taxonomy_path,
    show_col_types = FALSE,
    col_types = cols(.default = col_character())
  ) |>
    transmute(
      avibase_id = `taxon concept ID`,
      taxonomy_common_name = `English name`
    ) |>
    filter(!is.na(avibase_id), avibase_id != "") |>
    distinct(avibase_id, .keep_all = TRUE)
} else {
  tibble(
    avibase_id = character(),
    taxonomy_common_name = character()
  )
}

species_reference <- load_species_reference(species_reference_path) |>
  left_join(taxonomy_reference, by = "avibase_id", na_matches = "never") |>
  transmute(
    afring_number,
    avibase_id,
    common_name = coalesce(na_if(common_name, ""), taxonomy_common_name)
  ) |>
  filter(!is.na(afring_number), afring_number != "") |>
  distinct(afring_number, .keep_all = TRUE)

ring_daily_counts <- read_csv(
  ring_events_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  mutate(
    date = as.Date(ringing_date),
    season = assign_season_from_date(date),
    afring_number = clean_signed_number_key(afring_number)
  ) |>
  count(date, season, afring_number, name = "n_records") |>
  mutate(
    source = "ring_events",
    source_priority = unname(daily_count_source_priority[source])
  )

djp_daily_counts <- read_csv(
  djp_daily_counts_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  transmute(
    date = as.Date(date),
    season = assign_season_from_date(date),
    afring_number = clean_signed_number_key(afring_number),
    n_records = as.integer(n_records),
    source = "djp_daily_summary",
    source_priority = unname(daily_count_source_priority[source])
  )

# Consolidate daily counts ------------------------------------------------

season_source_selection <- bind_rows(
  ring_daily_counts |> distinct(season, source, source_priority),
  djp_daily_counts |> distinct(season, source, source_priority)
) |>
  mutate(
    source_priority = coalesce(
      source_priority,
      max(daily_count_source_priority) + 1L
    )
  ) |>
  arrange(season, source_priority, source) |>
  group_by(season) |>
  mutate(
    selected_source = case_when(
      preferred_daily_count_source %in% source ~ preferred_daily_count_source,
      TRUE ~ first(source)
    ),
    is_selected = source == selected_source,
    overlap_n_sources = n()
  ) |>
  ungroup() |>
  arrange(season, source_priority)

daily_counts <- bind_rows(ring_daily_counts, djp_daily_counts) |>
  left_join(
    season_source_selection |>
      filter(is_selected) |>
      select(season, selected_source = source),
    by = "season"
  ) |>
  filter(source == selected_source) |>
  arrange(date, afring_number, source_priority) |>
  distinct(date, afring_number, .keep_all = TRUE) |>
  left_join(species_reference, by = "afring_number") |>
  select(
    date,
    season,
    avibase_id,
    common_name,
    n_records
  ) |>
  arrange(date, avibase_id) |>
  rename(ringing_date = date)

# Write output ------------------------------------------------------------

write_csv(daily_counts, daily_counts_output_path, na = "")

cli_alert_success(
  "Wrote {nrow(daily_counts)} species-day rows to {daily_counts_output_path}"
)
