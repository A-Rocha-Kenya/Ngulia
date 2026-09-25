# Daily covariate configuration

This directory separates recorded daily data, source-linked operations history, and modeled weather. Its purpose is to make catchability information usable without treating missing effort information as zero.

## Core interpretation

Observed catch is not a direct measure of migrants passing Ngulia. It depends on the number of migrants aloft, the chance of light attraction or grounding, net position and exposure, vegetation around the lodge, and the team’s capacity to keep nets open and process birds. A change in catch can therefore reflect passage, weather, illumination, netting, habitat, staffing, or several of these together.

The evidence hierarchy is:

1. Recorded daily metadata already held in the curated data.
2. Explicit source-linked history in `operations_history.csv`.
3. Unknown or inference, which must remain labelled as such. Silence in a report is not evidence that conditions were unchanged.

## Operations history

`operations_history.csv` is an internal configuration/evidence register, not a curated dataset. It records source-linked historical states and events that may affect catch but are not measured consistently in the daily data, including lights, nets, playback, vegetation, capacity, and interruptions.

Each row has an explicit interval and temporal scope. A broad `period`, `reported_period`, `reported_session`, or `reported_state` is contextual evidence and must not be expanded into a daily zero/one variable. `daily_start_date`, `daily_end_date`, and `daily_values` contain the reviewed application decision for evidence that can validate or correct a daily field. `daily_values` uses auditable `field=value` pairs; an empty value means that the record remains contextual. Sources use verified PDF pages where applicable, or dated entries for field diaries and weather notes.

The table remains separate from `daily_coverage.csv` so unknown conditions are not converted to absence. Continuous variables such as net-hours, illuminance, playback sound level, and vegetation cover must not be reconstructed without direct measurement or an explicit, auditable method.

Its fields are:

| Field | Meaning |
| --- | --- |
| `start_date`, `end_date` | Interval reported by the source. |
| `covariate`, `value` | Historical domain and reported state or event. |
| `evidence_class`, `temporal_scope` | Source type and temporal precision. |
| `source_path`, `source_page`, `note` | Traceable source location and interpretation. |
| `evidence_id` | Stable identifier used by reconciliation QA. |
| `daily_start_date`, `daily_end_date` | Reviewed application interval when a source can be tied to ringing dates. |
| `daily_values` | Reviewed `field=value` assignments; only the model-facing fields are materialized in `daily_coverage.csv`. |
| `daily_review` | Date-convention and review decision for the application. |

### Historical interpretation

- Early catching used dawn nets south of the lodge; night nets below the floodlights were added later. Dawn netting moved north of the lights during the mid-1990s and the 1996 back line was optional when catch volume or staff constrained work.
- For the post-transition count sensitivity, `night_net_configuration` is treated as established from 1977, and `bush_net_configuration` is back bush through 1993, transition in 1994–1995, then front bush from 1996. The synthesis says northern use began in 1994 and became routine in 1995, but mixed `B`/`F` workbook codes make 1995 unsuitable as a stable-period observation. These period fields describe the physical arrangement; daily operation fields describe use.
- Lighting changed materially over time: early lodge lamps, reduced/faulty output in the 1980s, later project lamps, documented outages, and the 3.5 kW three-lamp configuration in 2013–15. Wattage is not a measurement of bird-effective light dose; do not infer output, spectrum, geometry, or nightly availability from a report’s silence. See [Ngulia light attraction: mechanisms, evidence and measurement](reviews/light_setup.md) for the light-specific review.
- Playback can alter total catch and species composition. `djp_tape` is a daily coded location/use field through 2014, not a record of species, volume, timing, or audibility. Later reports often distinguish nocturnal song playback from diurnal target lures, so these must not be collapsed into one unqualified playback covariate.
- The workbook decodes `T` as tapes at front and `t` as tapes behind lodge, both under “Night tape use.” It does not identify which speaker was at night nets versus bush nets, so those labels remain unresolved. Blank cells in covered DJP metadata mean none; dates outside coverage remain unknown.
- Elephant damage and vegetation recovery plausibly alter holding and netting conditions. Reported habitat states are contextual unless a source documents a particular event date.
- Team size and session length constrain processing capacity but do not measure net-hours. Explicit closures, delays, or short sessions are retained as events; no continuous historical team-size or effort series is inferred.

The decoded `djp_site` field has `outside_night_nets` records on 12 and 14 November 1974, whereas the historical synthesis describes night netting from 1976. No contemporary 1974 source was found to resolve this conflict. Both workbook observations are retained and explicitly flagged in `operations_history.csv`; they should be excluded in a site-history sensitivity analysis.

## Daily-table assembly

`scripts/intermediate/01_build_daily_context.R` retains the source-specific daily observations. `scripts/intermediate/02_build_mist_model.R` fits the unified three-state observed/ERA5 mist model. `scripts/curated/05_build_daily_coverage.R` builds the single external daily table.

`daily_coverage.csv` includes deterministic season and lunar variables, parsed team-size fields, observed mist evidence and one modeled three-state mist distribution, effort evidence, and the reviewed daily observations needed for count modeling. Raw `djp_*` fields are preserved; reconciled mist, rain, net sites, night/dawn operation, and nocturnal playback apply explicit source decisions from the history. A compact `operations_evidence_ids` field links affected dates back to full provenance in `operations_history.csv`. Qualitative and sparse historical details are not copied into the daily table. Model eligibility is created inside the relevant analysis.

The DJP workbook column `BS` is the source daily total. A numeric zero in that cell is retained as `daily_count_status = zero_in_daily_summary`; a blank cell remains a missing count. Only source-recorded zeros with independently documented operation are eligible for the exploratory catch plots and operating-day model.

## Source priorities and remaining gaps

The main operational sources are the 1969–2012 synthesis, contemporary early ringing accounts, annual reports, field diaries, and weather notes. The published *Scopus* annual accounts through autumn 1991 are now held in the reference library. The strongest remaining opportunities are original daily notebooks or diaries and privately circulated annual reports, especially for 1992–2003. Individual ringing-book scans are useful only where they contain a complete, legible effort note; bird records or partly completed effort headers must not be used to infer netting activity.

For field protocols and future direct measurement, see [Future Ngulia protocol standardization](planning/field_protocol.md). Dataset field definitions are in [dataset documentation](dataset.md).
