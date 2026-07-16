library(dplyr)
library(readr)
library(readxl)
library(tidyr)
library(stringr)
library(lubridate)
library(cli)

# Set paths ---------------------------------------------------------------

project_dir <- normalizePath(".", mustWork = TRUE)
source(file.path(project_dir, "scripts", "helpers", "data_paths.R"))
paths <- get_data_paths(project_dir)

daily_counts_dir <- paths$daily_counts_intermediate_dir
source_files_dir <- paths$daily_counts_raw_dir
ring_events_config_dir <- paths$ring_events_config_dir
dir.create(daily_counts_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path(project_dir, "scripts", "helpers", "ring_event_helpers.R"))

input_path <- file.path(
  source_files_dir,
  "djp_daily_and_annual_summaries_1969_2012.xlsx"
)
metadata_helper_path <- file.path(
  project_dir,
  "scripts",
  "helpers",
  "extract_djp_metadata_block.py"
)
species_output_path <- file.path(
  daily_counts_dir,
  "djp_daily_counts.csv"
)
metadata_output_path <- file.path(
  daily_counts_dir,
  "djp_daily_metadata.csv"
)

# Read workbook -----------------------------------------------------------

cli_h1("Extract DJP daily counts")

sheet1 <- read_excel(
  input_path,
  sheet = "Sheet1",
  col_names = FALSE,
  .name_repair = "minimal"
)
header_rows <- read_excel(
  input_path,
  sheet = "Sheet1",
  col_names = FALSE,
  n_max = 4,
  .name_repair = "minimal"
)

names(sheet1) <- paste0("V", seq_along(sheet1))
names(header_rows) <- paste0("V", seq_along(header_rows))

metadata_output_tmp <- tempfile(fileext = ".csv")
metadata_status <- system2(
  "python3",
  c(metadata_helper_path, input_path, metadata_output_tmp)
)

if (metadata_status != 0) {
  cli_abort("Failed to extract DJP metadata block via {metadata_helper_path}")
}

metadata_block <- read_csv(
  metadata_output_tmp,
  show_col_types = FALSE,
  col_types = cols(
    row_index = col_integer(),
    moon = col_character(),
    weather = col_character(),
    rain = col_character(),
    site = col_character(),
    tape = col_character(),
    pax = col_character()
  )
)

# Build species header mapping -------------------------------------------

species_header <- tibble(
  column_index = 6:69,
  species_code = as.character(unlist(header_rows[3, 6:69])),
  scientific_name = as.character(unlist(header_rows[4, 6:69]))
) |>
  filter(!is.na(species_code)) |>
  mutate(
    species_code = recode(
      species_code,
      HIEPEN = "AQUPEN",
      LANXXX = "LANCOLXLANISA",
      IDUPAL = "HIPPAL"
    ),
    code_key = clean_key(species_code)
  )

species_reference <- read_csv(
  file.path(ring_events_config_dir, "species_reference.csv"),
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  mutate(
    afring_number = clean_number_key(afring_number),
    code_key = clean_key(latin_abbreviation)
  ) |>
  filter(!is.na(code_key), !is.na(afring_number)) |>
  distinct(code_key, .keep_all = TRUE) |>
  transmute(
    code_key,
    afring_number
  )

species_header <- species_header |>
  left_join(
    species_reference |>
      rename(afring_from_code = afring_number),
    by = "code_key"
  ) |>
  mutate(
    afring_number = afring_from_code
  ) |>
  select(
    column_index,
    species_code,
    scientific_name,
    afring_number
  )

# Extract daily data ------------------------------------------------------

daily_data <- sheet1 |>
  mutate(row_index = row_number()) |>
  left_join(metadata_block, by = "row_index") |>
  slice(-(1:6)) |>
  transmute(
    year = suppressWarnings(as.integer(V1)),
    month = suppressWarnings(as.integer(V2)),
    day = suppressWarnings(as.integer(V3)),
    date = make_date(year, month, day),
    moon = blank_to_na(moon),
    weather = blank_to_na(weather),
    rain = blank_to_na(rain),
    site = blank_to_na(site),
    tape = blank_to_na(tape),
    pax = blank_to_na(pax),
    across(V6:V69, as.character)
  ) |>
  filter(!is.na(year), !is.na(month), !is.na(day))

# Species by day ----------------------------------------------------------

species_by_day <- daily_data |>
  pivot_longer(
    cols = V6:V69,
    names_to = "column_name",
    values_to = "count_raw"
  ) |>
  mutate(
    column_index = as.integer(str_remove(column_name, "^V")),
    n_records = suppressWarnings(as.integer(count_raw))
  ) |>
  filter(!is.na(n_records), n_records > 0) |>
  left_join(species_header, by = "column_index") |>
  select(
    date,
    afring_number,
    n_records
  ) |>
  arrange(date, afring_number)

# Daily metadata ----------------------------------------------------------

daily_metadata <- daily_data |>
  select(year, month, day, date, moon, weather, rain, site, tape, pax) |>
  arrange(date)

# Write outputs -----------------------------------------------------------
unmatched_codes <- species_header |>
  filter(is.na(afring_number)) |>
  pull(species_code)

if (length(unmatched_codes) > 0) {
  cli_abort(
    c(
      "Species header codes did not match `species_reference.csv` via `latin_abbreviation`.",
      "x" = "Unmatched codes: {paste(unmatched_codes, collapse = ', ')}"
    )
  )
}

write_csv(species_by_day, species_output_path, na = "")
write_csv(daily_metadata, metadata_output_path, na = "")

cli_alert_success(
  "Wrote {nrow(species_by_day)} DJP species-day rows to {species_output_path}"
)
cli_alert_success(
  "Wrote {nrow(daily_metadata)} daily metadata rows to {metadata_output_path}"
)
