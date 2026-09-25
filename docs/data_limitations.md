# Ngulia Data Limitations And Assumptions

This note records the main interpretation limits for analyses based on the curated Ngulia daily counts and daily metadata. It is intentionally practical: it describes what the current pipeline does and what that means for downstream trend analyses.

## Current Data Products

The main files used for daily analyses are:

- `data/04_curated/daily_counts.csv`: one row per species, date, and season with a positive count.
- `data/04_curated/daily_coverage.csv`: one canonical row per calendar day, with daily totals, coverage/effort evidence, moon, DJP metadata, unified mist-state probabilities, reviewed daily modeling fields, and ERA5 weather.
- `config/daily_covariates/operations_history.csv`: internal source-linked configuration used to review selected daily fields; it is not a curated dataset or a second daily table. Broad historical states remain there as qualitative evidence.

The season definition is analytical, not calendar-year based. Seasons turn over on October 20. The daily coverage table uses an October 20 to January 12 default window for each season, and extends the season end when source data continue later into January.

## Daily Count Construction

`daily_counts.csv` is built from two possible sources:

- daily summaries extracted from the DJP workbook
- daily summaries reconstructed from curated `ring_events.csv`

The source choice is made at the season level. If DJP daily-summary rows exist for a season, the DJP source is used for the whole season. Otherwise, the ring-event-derived source is used.

Important consequences:

- `daily_counts.csv` contains positive species-day counts only.
- Missing species rows are not explicit zeros.
- Missing dates in `daily_counts.csv` are not automatically zero-count days.
- The preferred count source is not chosen day by day, so a season with DJP daily summaries uses DJP consistently even if ring-event rows also exist.

## Coverage Construction

`daily_coverage.csv` is a calendar and metadata scaffold. Row existence means that a date is inside the analysis season window, not necessarily that ringing happened.

The current table includes:

- `all_birds_ringed`: total from the selected `daily_counts.csv` source
- `swallow_birds_ringed`: swallow and martin captures from the separate targeted daytime process
- `total_birds_ringed`: modeled total after subtracting `swallow_birds_ringed`
- `ringing_happened`: `TRUE` when `total_birds_ringed > 0`
- DJP metadata fields such as moon, weather, rain, site, tape, and pax
- derived moon variables
- unified observed/ERA5 mist-state probabilities and weather summaries

This table does not establish complete quantitative ringing effort. It recovers documented operating status for some dates, including a small number of operated zero-catch dates, but it does not supply net-hours. In the species-composition pipeline, zero filling is therefore restricted to dates where `ringing_happened == TRUE`.

## Zero-Filling Assumption

For the current composition analyses:

- reconstruct species zeros only within dates where `ringing_happened == TRUE`
- treat a missing species row on such a date as a zero for that species
- do not treat calendar rows with `ringing_happened == FALSE` as known zero-count ringing days
- do not fill across undocumented calendar gaps just because dates fall inside the seasonal window

This is conservative. It avoids turning the seasonal calendar scaffold or a metadata entry into effort data. Zero filling can be broadened only when an independent source establishes that ringing operated on the date.

## Observation Process Limits

Ngulia catch totals are not direct counts of all migrants passing through the region. Catch depends on migration intensity, weather, mist, moon, attraction to lights, net setup, playback, staffing, and processing capacity.

This means:

- high counts can reflect strong passage, strong grounding conditions, high catchability, high effort, or a combination of these
- low counts can reflect weak passage, poor grounding conditions, low effort, or missing coverage
- large fall events can dominate annual totals
- annual totals are difficult to interpret as absolute abundance without stronger effort correction

The current annual model is therefore labelled an adjusted positive-catch intensity index. It standardizes positive-catch dates for timing, moon, and ERA5-derived weather, but it is not an effort-corrected abundance index. The limited documented zero-catch sample is retained for restricted operating-day sensitivity work, not extrapolated across unknown dates.

## Effort And Protocol Limits

Important effort variables are incomplete or inconsistent over the full time series:

- total net length
- number of nets open
- time nets were open
- temporary closures during heavy catches
- number of ringers and extractors
- playback use
- processing bottlenecks

The local literature also describes protocol changes over time, including early hand collection and dawn netting, introduction of night netting, outdoor night-netting from 1976 onward, changes in dawn operations, larger recent teams, and playback use in some periods.

These changes can affect both total catch and species composition.

The primary species-composition analysis excludes seasons 1969–1976. Catches through 1975 came mainly from southern dawn nets; 1976 introduced intensive night netting but retained mixed dawn-only dates and is treated as a transition season. This removes the clearest early capture-regime break but does not remove later changes in lighting, net location, staffing, or playback.

Swallow and martin catches are excluded from the total-catch model because targeted daytime playback and swallow-net operation form a separate capture process. Their species-day records remain in `daily_counts.csv`, and their daily sum remains in `daily_coverage.csv` for audit and separate analysis.

The DJP PAX field is labelled “Team size — Ringers and others.” Plain numeric values and explicit additions such as `18+4EW` yield exact totals; values such as `18+EW` yield only a minimum-known team size. Team size is not equivalent to net-hours or processing effort.

## Weather, Moon, And Timing

Mist, rain, cloud base, wind, and moon conditions affect whether migrants are grounded and available to catch. Coverage is also structured around suitable moon periods rather than uniform full-season operation. One three-state mist model now retains direct DJP classifications where available and uses ERA5-calibrated probabilities elsewhere; missing-state uncertainty is propagated through the count analysis.

Species differ in seasonal timing. Missing early or late blocks can therefore bias species differently, even when total seasonal coverage looks similar.

## Practical Guardrails

Until better effort reconstruction is available:

- analyse common species separately from rare species
- fill species zeros only within the analysis-defined covered dates
- treat dates without ringing as unknown coverage, not known zero catch
- prefer relative composition or standardized catch over absolute abundance
- include date within season, weather, moon, and available operation metadata where possible
- treat protocol changes as real sources of heterogeneity

## Open Questions

- Can reports, diaries, or notebooks recover exact start and end dates for ringing blocks?
- Can effort variables such as nets, hours, staff, and playback be reconstructed by date or season?
- Can some no-catch calendar dates be confidently classified as covered days?
- Which species are common enough for stable trend estimation?
- Should fragmented or protocol-shifted seasons be excluded from the main trend analysis?
