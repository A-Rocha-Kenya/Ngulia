# Data files

This archive contains 5 UTF-8 CSV files with header rows. Empty cells mean a value is unavailable, unresolved, or inapplicable.

| File | Description |
| --- | --- |
| `ring_events.csv` | One cleaned ringing event per row, including biometrics, mapped ringer name, and moult fields when recorded. |
| `daily_counts.csv` | Positive species-day counts from the selected source. |
| `daily_coverage.csv` | Canonical daily catch, coverage/effort evidence, observed metadata, calibrated mist probability, and ERA5 weather. |
| `recoveries.csv` | Curated recovery and control movements involving Ngulia, with event-level provenance. |
| `operations_history.csv` | Source- and page-linked historical operations states and events; broad periods remain contextual rather than imputed daily measurements. |

## How the tables relate

- `ring_events.csv` records individual captures. `daily_counts.csv` gives positive species-day totals; for each season, it uses the historical DJP summary when available and otherwise derives counts from ring events. The two tables need not have identical daily totals.
- `daily_coverage.csv` has one row per date in the season calendar. Join it to `daily_counts.csv` by `ringing_date` and `season`. An absent species row or an empty daily total is not automatically a zero-catch day; use `daily_count_status` and `effort_status` to distinguish recorded zeros, missing counts, and operation evidence. `ringing_happened` reflects a positive catch after targeted swallow and martin catches are excluded.
- `operations_history.csv` records dated sources for station operations. `operations_evidence_ids` in `daily_coverage.csv` points to applied evidence; broad historical periods are context rather than daily measurements.
- `recoveries.csv` records separately curated movements involving Ngulia and is not keyed to `ring_event_id`.

`season` names the year in which an October–January season starts. `ringing_date` is the analysis date; captures from 20:00 onward normally belong to the next ringing day, subject to the source workbook's date convention.

## Documentation

The [field dictionary](https://github.com/A-Rocha-Kenya/ngulia-dataset/blob/main/data/README.md), [interpretation limits](https://github.com/A-Rocha-Kenya/ngulia-dataset/blob/main/docs/data_limitations.md), and [processing workflow](https://github.com/A-Rocha-Kenya/ngulia-dataset/blob/main/scripts/README.md) are maintained in the [GitHub repository](https://github.com/A-Rocha-Kenya/ngulia-dataset).
