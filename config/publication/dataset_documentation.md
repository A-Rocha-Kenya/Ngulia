## Dataset files

| File | One row represents | Main role |
| --- | --- | --- |
| `ring_events.csv` | One cleaned capture event for an individually marked bird. | Canonical individual ringing observations and biometrics. |
| `ring_event_moult.csv` | One ring event with decoded or unresolved moult information. | Moult observations linked to `ring_events.csv`. |
| `daily_counts.csv` | One species with a positive count on one date. | Selected daily species totals for count-based analyses. |
| `daily_coverage.csv` | One calendar date within a ringing season window. | Daily totals, coverage indicator, moon, operational metadata, and ERA5 weather. |
| `recoveries.csv` | One distinct recovery or control movement involving Ngulia. | Curated movements between Ngulia and another ringing or recovery location. |

`ring_event_moult.csv` joins to `ring_events.csv` through `ring_event_id`. `daily_counts.csv` joins to `daily_coverage.csv` through `ringing_date` and `season`. The recovery table is independent of the ring-event identifiers because it was curated from a separate historical recovery workbook.

Empty CSV fields represent unavailable, unresolved, or inapplicable values; field-specific distinctions are documented below. Files are UTF-8 comma-separated text with a header row.

<!-- github-only:start -->
## Repository structure

- `data/01_raw/`: source workbooks, weather downloads, and external archives. Do not edit unless updating source material.
- `data/02_reference/`: taxonomy lists, range maps, reports, and publications.
- `data/03_intermediate/`: regenerable extracts and QA outputs.
- `data/04_curated/`: analysis-ready project datasets.
- `data/05_derived/`: regenerated summaries, figures, website exports, and analysis products.
- `data/06_zenodo/`: generated Zenodo form worksheet and dataset README.
- `data/07_gbif/`: generated Darwin Core and GBIF metadata exports.
- `config/ring_events/`: source specifications, corrections, species mappings, measurement ranges, and moult rules.
- `config/website/`: taxonomy mappings used by the website pipeline.
- `config/publication/`: shared publication metadata, README prose, and GBIF field mappings.

All curated datasets are in `data/04_curated/`.

Data files are not tracked in Git. Raw and reference inputs are not distributed through GitHub; curated datasets are published through Zenodo, and Darwin Core exports through GBIF. Access instructions and rights for the source collections still need to be documented before public release.
<!-- github-only:end -->

## Key definitions

- `datetime` is the cleaned event timestamp. It preserves timing information but is not used as the analysis date.
- `ringing_date` is the canonical analysis date. Events at or after 20:00 are assigned to the following ringing day, unless a source file declares its raw date to be the ringing day with `raw_date_is_ringing_date`.
- `season` is the year in which the October-January ringing season starts. Dates from June through December use their calendar year; January-May use the previous year. This June 1 administrative boundary keeps the whole ringing season under one label even if its October start shifts slightly between years.
- `fat_ngulia` is the original Ngulia 0-4 fat score, based on the appearance of the furcular pit. `fat_kaiser` is the Kaiser 0-8 score, based on both the furcular pit and abdomen. The scales are retained separately and are not converted or assumed to be numerically equivalent.
- `daily_counts.csv` contains positive counts only. Missing species rows can be reconstructed as zero only for a documented date; a missing date is not automatically a zero-count day.
- `daily_coverage.csv` is a calendar scaffold, not evidence that ringing occurred. `ringing_happened` identifies dates with birds in the selected count source. Its default window starts on October 20 and extends beyond January 12 when source data do.

Detailed interpretation limits and analysis assumptions are included under **Interpretation limits** below.

## Data dictionary

### `ring_events.csv`

| Column | Type / unit | Description |
| --- | --- | --- |
| `ring_event_id` | text | Stable event key, normally the cleaned ring number plus `ringing_date`; timestamp information disambiguates the rare non-unique base key. |
| `season` | integer year | Year in which the October–January ringing season starts. |
| `ringing_date` | ISO date | Canonical ringing and analysis date after applying the source-specific date convention and night rollover. |
| `datetime` | ISO date-time | Cleaned local capture timestamp when source time was available; may be empty. |
| `ring_number` | text | Cleaned identifier engraved on the bird's ring. |
| `retrap` | boolean | `TRUE` when the ring has an earlier `ringing_date`, `FALSE` for its first event; empty when source coding conflicts with event history. |
| `afring_number` | integer code | AFRING taxon code. `0` represents an unresolved identity; negative project codes represent explicitly mapped hybrid labels. |
| `avibase_id` | text identifier | Avibase identifier for the resolved taxon; empty when unresolved. |
| `subspecies_avibase_id` | text identifier | Avibase identifier for an explicitly resolved subspecies or subspecies group derived from mapped note text; otherwise empty. |
| `common_name` | text | Project-standard English taxon name. |
| `species_code` | text identifier | eBird/Clements species or subspecies code associated with the Avibase identifier. |
| `age` | integer code | EURING age code `0`–`9`; definitions are given under **Age codes**. |
| `sex` | controlled text | `M`, `F`, `M?`, or `F?`; empty when unknown or invalid. |
| `wing` | millimetres | Source wing-length measurement after numeric parsing and range validation. |
| `weight` | grams | Source body-mass measurement after numeric parsing and range validation, exported to one decimal place. |
| `fat_ngulia` | integer score | Original Ngulia fat score, `0`–`4`; retained only for sources using that scale. |
| `fat_kaiser` | integer score | Kaiser fat score, `0`–`8`; retained only for sources using that scale. |
| `ring_note` | text | Pipe-separated retained source information, uncertainty, corrections, merge details, and QA conflicts that should not be silently discarded. |

### `ring_event_moult.csv`

| Column | Type / unit | Description |
| --- | --- | --- |
| `ring_event_id` | text | Foreign key to `ring_events.csv`. |
| `moult_note` | text | Original or normalized unresolved moult notation and any moult-specific QA conflicts. |
| `primary_moult_status` | controlled text | Overall state: `old`, `active`, `suspended`, or `complete`; empty when unresolved. |
| `n_old_primaries_remaining` | integer count | Reported number of old primaries remaining, `0`–`10`. |
| `body_moult_head` | score `0`–`3` | Positioned source body-moult code for the head; its biological meaning is not inferred. |
| `body_moult_upperparts` | score `0`–`3` | Positioned source body-moult code for the upperparts; its biological meaning is not inferred. |
| `body_moult_underparts` | score `0`–`3` | Positioned source body-moult code for the underparts; its biological meaning is not inferred. |
| `p1`–`p10` | controlled score | Primary-feather scores in source order. Nine-primary formats leave `P10` empty. |
| `s1`–`s6` | controlled score | Secondary-feather scores in source order. |
| `t1`–`t3` | controlled score | Tertial-feather scores in source order. |
| `tail1`–`tail6` | controlled score | Tail-feather scores in source order. |

Feather-score meanings and source-specific interpretation are documented under **Moult output and standardization**.

### `daily_counts.csv`

| Column | Type / unit | Description |
| --- | --- | --- |
| `ringing_date` | ISO date | Canonical ringing and analysis date. |
| `season` | integer year | Year in which the October–January ringing season starts. |
| `afring_number` | integer code | AFRING taxon code used to align daily summaries and ring-event-derived counts. |
| `common_name` | text | Project-standard English taxon name. |
| `n_records` | integer count | Positive number of birds for the species and date from the season-selected count source. |

### `daily_coverage.csv`

ERA5 fields summarize 00:00–08:00 local time at the project grid point. The `djp`-prefixed fields are decoded from the historical daily-summary workbook and are empty outside its coverage.

| Column | Type / unit | Description |
| --- | --- | --- |
| `ringing_date` | ISO date | Canonical ringing date in the season scaffold. |
| `season` | integer year | Year in which the October–January ringing season starts. |
| `total_birds_ringed` | integer count | Sum of `daily_counts.csv` for the date using the source selected for that season. |
| `ringing_happened` | boolean | `TRUE` when `total_birds_ringed > 0`; this is not a complete effort or documented-coverage indicator. |
| `djp_total_birds_ringed` | integer count | Total from the independently staged DJP daily-count source, including when it was not selected for `daily_counts.csv`. |
| `djp_moon_days_from_new_moon` | days | Historical signed moon-day value recorded in the DJP source. |
| `moon_days_from_new_moon` | integer days | Astronomically derived signed days from new moon; values after full moon are negative. |
| `moon_illumination_fraction` | fraction `0`–`1` | Astronomically derived illuminated fraction of the lunar disc. |
| `moon_phase_name` | controlled text | Derived phase: `new_moon`, `waxing_crescent`, `first_quarter`, `waxing_gibbous`, `full_moon`, `waning_gibbous`, `last_quarter`, or `waning_crescent`. |
| `djp_weather` | controlled text | Decoded historical mist/cloud condition; unrecognized source text is retained. |
| `djp_rain` | controlled text | Decoded historical rain condition. |
| `djp_site` | controlled text | Comma-separated decoded netting sites: back bush, front bush, outside night nets, lodge veranda, or swallow nets; `none` and `unknown` are explicit values. |
| `djp_tape` | controlled text | Comma-separated decoded playback locations; `none` is explicit. |
| `djp_pax` | controlled text | Decoded historical staffing or participant category; source category labels are retained. |
| `total_cloud_cover_mean` | fraction `0`–`1` | Mean ERA5 total cloud cover from 00:00–08:00 local time. |
| `cloud_base_height_mean_m` | metres | Mean ERA5 cloud-base height from 00:00–08:00 local time. |
| `total_precipitation_00_08_mm` | millimetres | Sum of ERA5 precipitation from 00:00–08:00 local time. |
| `wind_u_10m_mean_ms` | metres/second | Mean eastward ERA5 10-m wind component; negative values point westward. |
| `wind_v_10m_mean_ms` | metres/second | Mean northward ERA5 10-m wind component; negative values point southward. |
| `wind_speed_10m_mean_ms` | metres/second | Mean ERA5 10-m wind-speed magnitude. |
| `temperature_2m_mean_c` | degrees Celsius | Mean ERA5 2-m air temperature. |
| `relative_humidity_mean_pct` | percent | Mean relative humidity calculated from ERA5 2-m temperature and dew point. |
| `surface_pressure_mean_hpa` | hectopascals | Mean ERA5 surface pressure. |
| `mist_score_era5` | probability-like score `0`–`1` | Derived logistic proxy combining cloud cover, cloud-base height, and relative humidity; not a direct mist observation. |

### `recoveries.csv`

One row represents one distinct movement encounter involving Ngulia. Ordinary retraps at Ngulia are excluded. If one ring was encountered on multiple occasions away from its ringing site, each distinct encounter is a separate row. Ngulia is implicit as one endpoint; the `other_*` fields describe the non-Ngulia endpoint.

| Column | Type / unit | Description |
| --- | --- | --- |
| `recovery_id` | text identifier | Sequential project identifier `NGREC-0001`–`NGREC-0254`, assigned after sorting by direction, species, ringing date, ring number, and encounter date. |
| `direction` | controlled text | `from_ngulia` when ringed at Ngulia and subsequently encountered elsewhere; `to_ngulia` when ringed elsewhere and encountered at Ngulia. |
| `encounter_type` | controlled text | `control` for a bird encountered alive through ringing or recapture, `recovery` for other recovery reports, or `unknown` where the evidence cannot distinguish them. |
| `avibase_id` | text identifier | Repository-standard Avibase identifier for the species. |
| `common_name` | text | Repository-standard English common name. |
| `ring_scheme` | text | Ringing scheme or centre printed in the source, standardized where its identity is clear. |
| `ring_number` | text identifier | Normalized identifier engraved on the bird's ring; leading zeroes are significant. |
| `ringing_date_raw` | text | Ringing date exactly or closely retained from the selected evidence before ISO normalization. |
| `ringing_date` | ISO date or partial date | Normalized ringing date. Partial dates retain only known components and are never filled with 1 January. |
| `ringing_date_precision` | controlled text | Precision of `ringing_date`: `day`, `month`, `year`, `range`, or `unknown`. |
| `encounter_date_raw` | text | Encounter-date notation retained from the selected evidence, including parentheses, zeroes, seasons, or other uncertainty. |
| `encounter_date` | ISO date or partial date | Normalized date of recovery or control when the encounter date itself is known. Partial dates retain only known components. |
| `encounter_date_precision` | controlled text | Precision of `encounter_date`: `day`, `month`, `year`, `range`, or `unknown`. |
| `report_date` | ISO date or partial date | Date on which an otherwise undated recovery was reported. In the historical list, a date in parentheses is the date of the reporting letter, not the encounter date. |
| `other_location_raw` | text | Combined source description of the non-Ngulia endpoint before separation into site, region, and country. |
| `other_site` | text | Standardized locality at the non-Ngulia endpoint. |
| `other_region` | text | Province, district, oblast, or other region at the non-Ngulia endpoint. |
| `other_country` | text | Standardized country at the non-Ngulia endpoint. |
| `other_latitude` | decimal degrees | Latitude of the non-Ngulia endpoint; negative values are south. |
| `other_longitude` | decimal degrees | Longitude of the non-Ngulia endpoint; negative values are west. |
| `coordinate_source` | text | Provenance category for the non-Ngulia coordinates, such as an official notification, formatted list, or master spreadsheet. |
| `coordinate_precision` | controlled text | Spatial precision: `exact`, `locality`, `region`, `country`, or `unknown`. |
| `encounter_method` | text | Source-reported method or circumstance of the recovery or control, with limited normalization. |
| `encounter_condition` | controlled text | Standardized condition at encounter: `alive`, `dead`, or `unknown`. |
| `duration_days` | days | Elapsed days between ringing and encounter. A credible source value is retained; when inconsistent with exact dates, the date-derived value is used and documented. |
| `distance_km` | kilometres | Movement distance reported by the selected evidence or, where documented, curated from endpoint coordinates. |
| `ringing_age_code` | EURING code | Source age code at the original ringing event. |
| `ringing_sex` | controlled text | Sex at ringing: `M` or `F`; empty when unknown or not credible. |
| `ringing_wing_mm` | millimetres | Wing length measured at the original ringing event. |
| `ringing_mass_g` | grams | Body mass measured at the original ringing event. |
| `ringing_fat_score` | source score | Fat score measured at the original ringing event; the historical source scale is retained. |
| `encounter_age_code` | EURING code | Source age code at the recovery or control encounter. |
| `encounter_sex` | controlled text | Sex at encounter: `M` or `F`; empty when unknown or not credible. |
| `encounter_wing_mm` | millimetres | Wing length measured at the recovery or control encounter. |
| `encounter_mass_g` | grams | Body mass measured at the recovery or control encounter. |
| `encounter_fat_score` | source score | Fat score measured at the recovery or control encounter; the historical source scale is retained. |
| `primary_source` | project-relative path | Highest-precedence project source used for the curated row. |
| `primary_source_locator` | text | Sheet row, document entry, page, image, email date, or other locator within `primary_source`. |
| `supporting_sources` | pipe-separated paths | Other project sources describing or corroborating the same movement. |
| `source_count` | integer count | Number of primary plus supporting source references associated with the row. |
| `curation_status` | controlled text | `complete`, `incomplete`, `conflict_resolved`, or `needs_review`. Completeness refers to the surviving evidence, not necessarily to every optional measurement. |
| `curation_notes` | text | Material uncertainty, conflict resolution, inferred value, split event, or other decision that should not be hidden. |

Empty fields mean unavailable, unresolved, or inapplicable. Parenthesized recovery-list dates are mapped to `report_date`; all 21 such rows deliberately leave `encounter_date` empty. The one-off source inventory, duplicate accounting, conflict resolutions, and validation results are retained as an intermediate audit in `data/03_intermediate/recoveries/recoveries_audit.md` and are not part of the public data package. This manually curated table is canonical; no script regenerates it.

<!-- github-only:start -->
## Software setup

Install the required R packages from the project root:

```r
source("scripts/setup/01_install_dependencies.R")
```

The DJP metadata extractor uses Python 3 and only Python standard-library modules.

## Run the pipeline

Run scripts from the project root, in this order.

```r
# Curated data ------------------------------------------------------------
source("scripts/curated/01_build_ring_events.R")
source("scripts/curated/02_extract_djp_daily_counts.R")
source("scripts/curated/03_build_daily_counts.R")
source("scripts/curated/04_build_era5_daily_weather.R")
source("scripts/curated/05_build_daily_metadata.R")

# Derived products --------------------------------------------------------
source("scripts/derived/00_build_readme.R")
source("scripts/derived/01_summarize_curated_data.R")
source("scripts/derived/02_build_website_exports.R")
source("scripts/derived/03_plot_season_matrices.R")
source("scripts/derived/04_build_zenodo_package.R")
source("scripts/derived/05_build_gbif_export.R")
```

| Step | Purpose | Main outputs |
| --- | --- | --- |
| `01_build_ring_events.R` | Imports, cleans, and validates annual ringing workbooks. | `ring_events.csv`, `ring_event_moult.csv`, ring-event QA |
| `02_extract_djp_daily_counts.R` | Stages DJP species-day counts and metadata. | `data/03_intermediate/daily_counts/` |
| `03_build_daily_counts.R` | Selects the preferred count source by season. DJP is preferred when available for a whole season. | `daily_counts.csv` |
| `04_build_era5_daily_weather.R` | Produces 00:00-08:00 local ERA5 daily weather. | `era5_daily_weather.csv` |
| `05_build_daily_metadata.R` | Builds the daily coverage, metadata, and weather table. | `daily_coverage.csv` |
| `00_build_readme.R` | Builds the GitHub README from shared metadata and authored prose. | `README.md` |
| `01_summarize_curated_data.R` | Creates summary tables. | `data/05_derived/summaries/` |
| `02_build_website_exports.R` | Creates website JSON exports. | `data/05_derived/website/` |
| `03_plot_season_matrices.R` | Produces season-matrix figures. | `data/05_derived/figures/season_matrices/` |
| `04_build_zenodo_package.R` | Builds a worksheet for completing the online Zenodo form. | `data/06_zenodo/zenodo_form.md` |
| `05_build_gbif_export.R` | Builds the sampling-event Darwin Core Archive with daily events, individual captures, and bird-level measurements. | `data/07_gbif/` |
<!-- github-only:end -->

## Processing and standardization

### How ring events are built

`scripts/curated/01_build_ring_events.R` is the main ingestion and cleaning script. It converts heterogeneous annual workbooks from `data/01_raw/ring_events/` into a consistent event table while preserving source references in the QA outputs.

The script applies these steps in order:

1. **Read source-specific workbook regions.** `config/ring_events/file_specs.csv` identifies the file, sheet, header and final rows, expected years, and source-specific column conventions. It also controls exceptional date/time handling, swapped age and sex columns, retrap-code use, and fat scale.
2. **Apply explicit source corrections.** `config/ring_events/corrections.csv` records known row or row-range corrections to dates, species fields, measurements, and shifted columns. These corrections remain separate from the raw workbooks.
3. **Construct dates and seasons.** Raw date and time fields are parsed into `datetime`; `ringing_date` is constructed using the source date convention and 20:00 rollover rule; `season` is then derived from `ringing_date` using the June 1 boundary described above.
4. **Resolve species identity.** `species_lookup.csv` maps accepted numeric codes, Ngulia codes, abbreviations, and names to AFRING numbers. `species_reference.csv` adds project-standard common names, Avibase IDs, and website species codes. Missing, unmatched, or conflicting species identities are retained as AFRING number `0`. If one ring number is assigned to different species across events, the conflicting values are recorded in `ring_note`.
5. **Clean biological fields.** Age and sex are converted to controlled project values. Fat scores are assigned to `fat_ngulia` or `fat_kaiser` according to the source specification. Wing and weight are parsed and checked against species-specific ranges from `measurement_ranges.csv`; invalid measurements are set to missing and recorded in QA.
6. **Handle repeated rings.** Records with the same ring number on the same `ringing_date` are merged into one event. The `retrap` field is compared with earlier event-day history for that ring. When history and the raw retrap code disagree, `retrap` is left missing and the conflict is described in `ring_note` and the QA log.
7. **Decode moult.** Source-specific columns and expected sequence lengths are described in `moult_specs.csv`. The pipeline decodes feather and body-moult scores where their structure is sufficiently clear, while retaining unresolved source notation in `moult_note` and the component-specific QA log.
8. **Add taxonomy and subspecies.** Standard species metadata are joined to the cleaned events. When configured, labels extracted from `ring_note` and matched through `subspecies_lookup.csv` add a subspecies Avibase ID.
9. **Export curated and QA products.** The script writes `ring_events.csv`, `ring_event_moult.csv`, the row-level issue logs, and the source-file audit.

Rows need a valid date, allowed October-January event month and source year, ring number, an initial species value after unknown coding, and non-recovery status to enter `ring_events.csv`. A later cross-event ring/species conflict sets `afring_number` to `0` without removing the event. Rows mapping to AFRING code `9999` (`Lost or destroyed ring`) are excluded because they do not represent taxon occurrences. Rows marked with raw retrap code `X` are excluded from `ring_events.csv`; identifiable movement records are curated independently in `recoveries.csv`.

### How encoded values are parsed and standardized

Explicit row-level fixes in `config/ring_events/corrections.csv` are applied before the general rules below. They document recoverable entry errors such as shifted fields, duplicated digits, and values combined with adjacent fields; the raw workbooks are not edited.

| Field | Source parsing and standardized output |
| --- | --- |
| Date and time | Excel dates and common year-month-day, day-month-year, and month-day-year text are parsed. Times may be Excel fractions, decimal hours, four-digit `HHMM`, or clock text. A missing time produces date precision rather than an invented event time. `ringing_date` and `season` are then derived as described under **Key definitions**. |
| Ring number | Text is uppercased, whitespace is removed, and characters other than letters, digits, `/`, and `-` are discarded. A missing result excludes the row. |
| Event identifier | `ring_event_id` normally combines the cleaned ring number and `ringing_date` as `RING__YYYYMMDD`. If that base is not unique, the cleaned timestamp is used instead. The same identifier links `ring_events.csv` to `ring_event_moult.csv`. |
| Species | Numeric AFRING and Ngulia codes are normalized as numbers; text labels are lowercased and punctuation is ignored for matching. Matching priority is explicit AFRING number, Ngulia number, Ngulia text, then the general species label. Text may match a configured Latin abbreviation, Ngulia abbreviation, English name, scientific name, or AviList English name in `species_lookup.csv`. Missing, unmatched, or disagreeing species identities produce `afring_number = 0`; configured `-1` values identify unresolved *Lanius* hybrid labels whose true AFRING number is not available. Conflicting values across events carrying the same ring number are retained in `ring_note`. |
| Taxonomy | `avibase_id`, `common_name`, and `species_code` are joined through `species_reference.csv` and the `auk` taxonomy rather than parsed independently from each workbook. Pipe-separated `ring_note` tokens can add `subspecies_avibase_id` only when the species-and-note combination is explicitly mapped in `subspecies_lookup.csv`. |
| Age | Source values are standardized to the numeric EURING subset `0`-`9`; details are given below. The pipeline does not calculate a bird's age from an earlier capture. |
| Sex | `1`, `M`, `m`, and `Male` become `M`; `2`, `F`, `f`, and `Female` become `F`; `3`, `(M)`, and `Male?` become `M?`; `4`, `(F)`, and `Female?` become `F?`. Blank, `0`, `?`, and `Unknown` become missing. Any other value also becomes missing and is reported in QA. |
| Wing and weight | Decimal commas are converted to decimal points and the result is parsed numerically. Values outside the configured species range, or the global fallback range when no species range exists, become missing and are reported in QA. Weight is exported to one decimal place. |
| Fat | The source file specification determines whether a column uses the Ngulia or Kaiser scale. Integer-like values such as `3`, `3.0`, or `3,0` are accepted. `?` and `Unknown` become missing. Ngulia accepts `0`-`4`; Kaiser accepts `0`-`8`; out-of-range or nonnumeric values become missing and are reported in QA. The scales are never converted into one another. |
| Retrap | The final `retrap` value is derived from event history: it is `TRUE` when the cleaned ring number has an earlier `ringing_date`, otherwise `FALSE`. In source files that use retrap codes, uppercase code `2` means retrap and `X` marks a recovery row that is excluded from this dataset. Other nonblank codes mean not-retrap. If a nonblank source code disagrees with event history, final `retrap` is missing and the disagreement is retained in `ring_note` and QA. |

#### Age codes

Age is a plumage-based observation following the [EURING Exchange Code](https://euring.org/files/documents/E2020ExchangeCodeV202.pdf), not an age recalculated from the known history of a ring. Codes change at the calendar-year boundary.

| Code | Meaning |
| --- | --- |
| `0` | Age unknown or not recorded. |
| `1` | Pullus: nestling or chick not yet able to fly freely. |
| `2` | Full-grown and able to fly freely, but age otherwise unknown. |
| `3` | First calendar year; hatched during the current calendar year. |
| `4` | After first calendar year; hatched before the current calendar year, exact year unknown. |
| `5` | Second calendar year; hatched during the previous calendar year. |
| `6` | After second calendar year; hatched before the previous calendar year, exact year unknown. |
| `7` | Third calendar year; hatched two calendar years earlier. |
| `8` | After third calendar year; older than code `7`, exact year unknown. |
| `9` | Fourth calendar year; hatched three calendar years earlier. |

Blank or invalid age values become `0`. The uncertain source forms `2(3)`, `2(4)`, `3(2)`, `3?`, and `?3` are conservatively standardized to `2`, with the original value retained in `ring_note`. Valid but unusual codes `7` and `9` are retained and receive a warning in `ring_note` and QA. Letter codes for ages above `9` are not currently accepted by this pipeline.

### Moult output and standardization

Moult notation varies substantially among years. The pipeline therefore uses a source-specific, conservative mapping and exports one wide, human-readable `ring_event_moult.csv`.

#### Exported moult structure

Each row represents one ring event and is linked to `ring_events.csv` by `ring_event_id`. A row is exported when it contains at least one decoded moult value or unresolved source notation retained in `moult_note`.

| Exported column | Content |
| --- | --- |
| `ring_event_id` | Key linking the moult record to the corresponding ring event. |
| `moult_note` | Original or normalized source notation that should not be silently discarded, including unresolved values and QA conflicts. Moult text is kept separate from `ring_note`. |
| `primary_moult_status` | Overall primary-moult state: `old`, `active`, `suspended`, or `complete`. |
| `n_old_primaries_remaining` | Source count of old primaries, from `0` to `10`, when supplied. |
| `body_moult_head`, `body_moult_upperparts`, `body_moult_underparts` | The three positioned source body-moult codes, restricted to `0`-`3`. Their biological meanings are not inferred. |
| `P1`-`P10` | Primary-feather scores in source order. Nine-primary formats leave `P10` missing. |
| `S1`-`S6` | Secondary-feather scores in source order. |
| `T1`-`T3` | Tertial-feather scores in source order. |
| `Tail1`-`Tail6` | Tail-feather scores in source order. |

The positioned feather columns use this common exported vocabulary:

| Exported score | Meaning | Source schemes |
| --- | --- | --- |
| `0` | Old feather. | Legacy Ngulia and SAFRING-style sheets. |
| `1` | Feather missing or in pin. | Legacy Ngulia and SAFRING-style sheets. |
| `2` | New feather grown to at most one third. | Legacy Ngulia and SAFRING-style sheets. |
| `3` | New feather between one and two thirds grown. | Legacy Ngulia and SAFRING-style sheets. |
| `4` | New feather more than two thirds grown, with sheath remaining. | Legacy Ngulia and SAFRING-style sheets. |
| `5` | Fully grown new feather. | Legacy Ngulia and SAFRING-style sheets. |
| `8` | Fully grown feather whose age cannot be determined. | SAFRING-style sheets only. |
| `S` | Summer-generation feather. | Legacy Ngulia sheets only. |

The feather columns must be imported as text because they contain numeric-looking scores plus `S`. A simple lossless `readr` import is `read_csv("data/04_curated/ring_event_moult.csv", col_types = cols(.default = col_character()))`; convert individual numeric-only columns afterward when needed.

#### Source mapping and processing

`config/ring_events/moult_specs.csv` assigns each workbook its source columns, expected primary length, overall-status scheme, and feather-score scheme. The processing then follows these rules:

1. Source columns are read and combined in their original order. Empty positions in pipe-separated sequences are retained so that later scores are not shifted to the wrong feather.
2. Legacy Ngulia feather codes use the documented `0`-`5` progression. Source `O` maps to `0`, `N` maps to `5`, and `9` or `S` maps to exported `S`.
3. The 2020-2023 SAFRING-style sheets retain `0`-`5` and SAFRING code `8`. Legacy `O`, `N`, `9`, and `S` aliases are not applied to these sheets.
4. Exact structural variants are normalized only when positions remain unambiguous: scalar primary `0` becomes an all-zero sequence; an 11-character sequence containing one repeated score is reduced to ten positions; combined primary, secondary, and tertial strings are split using their configured lengths; and a nine-character secondary-plus-tertial string is split into six secondary and three tertial positions when no separate tertial value exists.
5. Structured note text such as `S1=...`, `1.1=...`, `T1=...`, or `1.2=...` can fill otherwise empty secondary or tertial positions. If a note conflicts with a dedicated score column, the conflicting component is left missing and both representations are retained in `moult_note` and QA.
6. Historical Ngulia overall-status codes map as `0 = old`, `1 = active`, `2 = suspended`, and `5 = complete`. Other summary codes remain unresolved unless a complete primary sequence supplies the status.
7. A complete primary sequence containing only `0`-`5` determines `primary_moult_status`: any score `1`-`4` means `active`; all `0` means `old`; all `5` means `complete`; and a mixture of only `0` and `5` means `suspended`. This sequence-derived status takes precedence over a conflicting historical summary, with the disagreement recorded in `moult_note` and QA.
8. Unsupported codes are not guessed. If sequence positions are clear, valid positions are retained and only unsupported positions are missing. If positions cannot be established, the whole affected component remains missing. The original notation and the action taken are retained in `moult_note` and the component-specific QA issue.

The pipeline does not apply an assumed EURING crosswalk: `V`, `X`, and other unsupported letters remain unresolved unless a source-specific meaning is documented later. The implemented mappings are based on the coding notes embedded in the 2006-2007 Ngulia workbook, the primary-moult states described in the 2014 main report, and the documented SAFRING feather-score definitions.

## Other processing decisions

- ERA5 mist score is a derived proxy based on cloud cover, cloud-base height, and relative humidity.
- Recovery taxonomy and locations are standardized with files in `config/website/`.

<!-- github-only:start -->
## Diagnostics and additional analysis

Diagnostics are optional and do not alter curated data.

```r
source("scripts/diagnostics/plot_ring_event_measurements.R")
source("scripts/diagnostics/qa_daily_metadata.R")
source("scripts/diagnostics/qa_ringing_weather_models.R")
source("scripts/diagnostics/compare_daily_count_sources.R")
source("scripts/diagnostics/assess_ring_event_date_modes.R")
```
<!-- github-only:end -->

## Data quality and validation

### Ring-event QA

`01_build_ring_events.R` runs QA while cleaning the source workbooks and writes three complementary outputs to `data/03_intermediate/ring_events/qa/`:

- `ring_events_issues.csv`: machine-readable issues with the source file, sheet, row, affected value, explanation, and action taken.
- `ring_events_issues.md`: the same issues grouped by type for review, including the original spreadsheet-row context.
- `source_file_audit.csv`: one summary row per source sheet, including imported and exported rows, missing dates/times, same-day merges, invalid fields, and moult decoding results.

The `action` column in the issue log records what the pipeline did:

| Action | Meaning |
| --- | --- |
| `exclude_row` | The row cannot define a valid ring event and is omitted from `ring_events.csv`. |
| `replace_species_unknown` | The row is retained with `afring_number = 0`; conflicting source values are appended to `ring_note` when applicable. |
| `replace_age_unknown` / `replace_sex_unknown` | The row is retained with age `0` or a missing sex value. |
| `replace_field_missing` | The row is retained, but the invalid measurement or decoded moult field is left missing. |
| `replace_status_from_sequence` | A complete primary-feather sequence supplies the status when the historical overall status is unsupported or conflicts with it; the source value and derived interpretation are retained in `moult_note`. |
| `replace_retrap_missing` | The event is retained with `retrap` missing and the inconsistency appended to `ring_note`. |

Checks and consequences are:

| Check | What is tested | Result |
| --- | --- | --- |
| Date and source range | Date parsing, October-January month, and the expected year range for the source file. A missing time is allowed. | Invalid-date or out-of-range rows are excluded. |
| Ring number | A cleaned ring number is present. | Missing ring numbers are excluded. |
| Species identity | Species is present, matches the lookup, and agrees across source columns. | Missing, unmatched, or conflicting identities are retained as AFRING `0`. |
| Age and sex | Age uses numeric EURING codes `0`–`9`; sex uses the accepted source mappings. | Invalid age becomes `0`; uncertain historical notation such as `2(3)` or `3?` becomes age `2` with the original value in `ring_note`. Valid but unusual ages `7` and `9` are retained with a warning in `ring_note`. Invalid sex becomes missing. |
| Wing and weight | Values are numeric and within the configured species range. | The invalid measurement is set to missing; the event is retained. |
| Fat | `fat_ngulia` is 0-4 and `fat_kaiser` is 0-8, according to the configured source scale. | The invalid score is set to missing; the event is retained. The two scales are not converted. |
| Moult | Overall status, old-primary count, primary, secondary, tertial, tail, and body notation are checked independently against the configured source scheme. Structured text is compared with dedicated score columns, and a complete primary sequence is compared with the reported overall status. | Valid positions and components are retained. Unresolved positions remain missing and raw notation is preserved in `moult_note`. Conflicting duplicate representations are left missing; when only overall status conflicts, the sequence-derived status is used and the disagreement is reported. |
| Same-day records | The same ring number occurs more than once on one `ringing_date`. | Rows are merged into one event; merge counts are reported in the file audit. |
| Ring-species consistency | One ring number resolves to more than one species across the dataset. | Affected events use `afring_number = 0`; the conflicting values are appended to `ring_note`. |
| Retrap consistency | The raw retrap code agrees with whether the ring has an earlier event-day record. | On disagreement, `retrap` is left missing and an explanatory text is appended to `ring_note`. |

The separate `assess_ring_event_date_modes.R` diagnostic compares alternative source-date interpretations with DJP daily counts. It supports review of `raw_date_is_ringing_date` settings but does not change curated data automatically.

`scripts/analysis/01_composition_trend_analysis.R` is a separate exploratory analysis that writes models, figures, and tables to `data/05_derived/analysis/composition_trends/`.

<!-- github-only:start -->
## Rebuilding after changes

- Change ringing source specifications or corrections: rebuild ring events, then daily counts, daily coverage, and derived products.
- Change the preferred source, `ringing_date`, or season definition: rebuild all curated and derived products.
- Change taxonomy or the manually curated `recoveries.csv`: rebuild website exports.

## Website export

`02_build_website_exports.R` reads curated daily counts, the manually curated recovery table, and taxonomy mappings, then writes JSON to `data/05_derived/website/`.

For local website syncing, set `NGULIA_PROJECT_DATA_DIR` to the absolute path of this project's `data/` directory in the website repository's `.env.pipeline.local`, then run `npm run preprocess` there.
<!-- github-only:end -->

## Related resources

The GBIF export in `data/07_gbif/` uses confirmed capture dates as the Event core, individual ringing records as the Occurrence extension, and biometric and moult observations as bird-level ExtendedMeasurementOrFact rows. Daily species counts and environmental variables are excluded; the EML description links to the complete Zenodo research dataset.
