# Daily capture model: review and proposed approach

**Dated analysis review (19–21 September 2026).** This records the reasoning and results available at that review, including the revised distinction between historical configuration and daily deployment. It is not a step in the dataset build or the current source for model results. Current scripts and reports are maintained in [ngulia-analysis](https://github.com/A-Rocha-Kenya/ngulia-analysis); reusable data definitions are in the [data README](../../data/README.md).

## Recommendation

Retain a flexible count model for positive-catch intensity and treat documented-operation playback as a sensitivity on the same positive-catch response. A separate operation-day estimand would require more complete operated zeroes. Use operations history to define interpretation and comparable periods. It is not a complete daily effort series and cannot, by itself, identify a historical migration-abundance trend.

Conceptually, daily catch depends on migrants available, attraction/retention, capture opportunity and processing capacity. Weather affects both birds and the decision to operate. Catch volume can itself shorten netting. Consequently, an association with an operational variable is not necessarily its causal effect.

## What the present analysis establishes

- The revised main model starts in 1977 and excludes the 1994–1995 transition; pre-1977 totals remain descriptive. It uses annual fixed effects and smooth effects of date, moon and weather. Its negative-binomial likelihood nevertheless includes zero, although the input excludes zeros.
- Saved season-block validation favours the post-transition M4 over timing alone: log-scale RMSE is 1.273 versus 1.862, and held-out deviance reduction is 55.3%. This supports retaining weather as a predictive component, but does not validate an abundance interpretation.
- M4-S, M5 and M6 use the same 824 positive-catch dates in 36 seasons, 1977–2014, excluding both 1994 and 1995. M4-S is the M4 daily-covariate baseline with a smooth year term. Held-out log RMSE is 1.177 for M4-S, 1.179 after adding a fixed back/front bush category (M5), and 1.160 after adding nocturnal playback (M6). Held-out deviance reduction falls from 61.0% to 60.4% to 59.2%. The mixed scores do not establish either added effect.
- In separate linear-year sensitivity fits on those same dates, average annual change is 3.3% for M4, 0.8% for M5, and approximately 0.0% for M6. The M5 and M6 intervals include zero. The smooth-year M5 front/back contrast is 1.06 (95% interval 0.65–1.73), so the linear-year attenuation depends heavily on the imposed trend shape and cannot be attributed specifically to the net move.
- The earlier binary sensitivity explained 62.6% of deviance with observed mist versus 45.6% with the ERA5 proxy on the same 1,100 positive dates. It motivated the replacement unified model: detailed observations now fix a three-state mist condition, while ERA5 supplies probabilities only where the state is missing.
- The curated calendar contains 1,093 documented-operation dates, 167 dates inferred from positive catch, two positive-catch/site conflicts, 101 documented non-operation dates and 3,344 unknown dates. Twenty documented-operation dates have a source-recorded zero; they are concentrated in 1972–1994.
- The history has 107 source-linked records. Sixty-three carry reviewed daily values; broader states remain contextual. The current daily table ends in 2023, so the 2024 evidence cannot yet be evaluated against catches.

The revised post-transition primary model explains 59.7% of fitted deviance across 20 mist-state imputations. Its annual index pools mist-state and coefficient uncertainty.

## Data issues resolved in the reconciliation

**Missing counts and recorded zeroes are now distinct.** The context builder retains the workbook daily-total field: 120 numeric zeroes are `zero_in_daily_summary`, while 3,345 blank or unavailable totals remain `missing`. M4-S, M5 and M6 fit positive-catch dates only. The 20 source-recorded zeroes with independent operation evidence remain available for a separate future operation-day analysis. Unknown calendar dates are never used as zeroes.

**Playback and rain blanks now follow the source convention.** Within the DJP metadata block, blank night-tape and rain cells mean recorded absence according to the workbook legends. Dates outside that source coverage remain unknown. Reviewed reports separately record nocturnal and diurnal playback.

**Team size is not uniformly exact and rises with time.** Retain it in exploratory coverage plots; do not use it as an M5 adjustment or effort offset. A single coefficient could absorb a general long-term change. This leaves any real staffing effect unresolved.

**Net codes retain their historical meaning.** Early `back_bush` refers to the southern/back bush site and is not equated with the northern back line added in 1996. The unresolved 1974 workbook `NB` records versus the synthesis's 1976 night-net introduction are retained as two explicit source conflicts.

**Configuration and daily use are separate.** For post-transition comparisons, night-net configuration is established from 1977. Bush-net configuration is back bush in 1977–1993, transitional in 1994–1995, and front bush from 1996. The synthesis says northern use began in 1994 and became routine in 1995, while the workbook retains mixed `B`/`F` codes in 1995. M5 adds a fixed back/front category on the two stable periods, with a smooth year effect instead of unrestricted annual fixed effects. This estimates a period contrast only under the smoothness assumption; other simultaneous changes can contribute.

**Tape locations remain unresolved.** The workbook defines `T` as front tapes and `t` as tapes behind the lodge under “Night tape use.” It does not identify a night-net versus bush-net tape. Preserve those source categories and use the supported nocturnal playback indicator in M6 until speaker locations can be verified.

**Playback overlaps strongly with period.** Among the 824 comparable dates, playback occurs on 38 of 367 back-bush dates and 194 of 457 front-bush dates. All back-bush playback rows are in 1993 and carry the same `t` code. The synthesis independently confirms that experiments began in 1993 in the southern bush. This is one season-wide exposure pattern rather than 38 independent seasons. M6 can use later within-season variation, but cannot cleanly separate a general playback effect from all changes accompanying the bush-net move.

**Align overnight events.** Reconcile report/diary dates with the response's canonical ringing date. In particular, the 6/7 December 1986 interval describes one overnight episode, not necessarily two independent disrupted operations. A setup date does not establish continued availability.

## How to use the history

| Evidence | Proposed use | Interpretation to avoid |
| --- | --- | --- |
| Exactly dated outages, delays and interruptions | Source-linked event classes; predictions and residual checks; fits with and without documented disrupted dates | Unmentioned dates were fully operational |
| Explicit opening/closing times and net dimensions | Reconstruct effort only for fully described intervals; retain night/day and closure reason | Turning a partial diary note into full-day net-hours |
| Lighting and net-layout periods | Annotate indices; compare trends within broadly comparable configurations; alternative transition boundaries | Known daily light dose or constant deployment |
| Reported vegetation state | Habitat-period sensitivities, especially for dawn catch | A measured continuous vegetation-cover series |
| Session totals and manned-night counts | Audit calendar coverage and target extraction of missing dates | Expanding enclosing intervals into consecutive operated nights |
| Playback records and policies | Separate nocturnal migrant playback from diurnal target lures; use explicit daily records where available | Treating a 2024 nocturnal policy as absence of all playback |
| Closures caused by high catch or small team | Flag potential capacity limitation; assess influence; later model within-night dynamics if available | An independent causal predictor, or a known numerical censoring threshold |

Keep the source history intact. Build analysis-specific event classifications separately, with explicit unknown values and source provenance. Sparse events generally support sensitivity analysis more credibly than many separately estimated coefficients. Excluding busy dates is itself selective, so report such exclusions alongside the all-date result rather than replacing it.

## Model A: long-term positive-catch intensity

Fit a zero-truncated negative-binomial additive model to positive recorded catches:

\[
Y_{dy}\mid Y_{dy}>0 \sim \operatorname{ZTNB}(\mu_{dy},\theta),\qquad
\log\mu_{dy}=\alpha_y+f(\mathrm{season\ day})+g(\mathrm{moon})+h(\mathrm{mist})+r(\mathrm{rain})+\boldsymbol{\beta}^{T}\mathbf{W}_{dy}.
\]

Here `W` contains additional weather terms supported by validation; these can remain smooth as in the current model. Start with annual fixed effects for continuity with the existing index. Compare partial pooling for sparse seasons, explicitly acknowledging its assumptions.

Use the conditional positive mean for predictions. With the NB2 parameterization it is `mu / (1 - (theta / (theta + mu))^theta)`, not simply `mu`. Compare the resulting annual index with the existing ordinary-NB index to quantify the practical effect of truncation. [glmmTMB documents a zero-truncated NB2 family](https://glmmtmb.github.io/glmmTMB/reference/nbinom2.html); it is one implementation option, with spline terms specified and checked explicitly.

This is a descriptive conditional model. Truncation handles the response support; it does not correct selective attendance, undocumented effort or incomplete reporting. Label the result “weather-adjusted positive-catch intensity.”

Do not add lighting-era or habitat-period main effects alongside unrestricted annual fixed effects: variables constant within a year lie in the span of those effects. Replacing annual effects with a smooth trend or random effects may yield numerical estimates, but separation then depends on the imposed trend/distribution assumptions. Present such models as sensitivity scenarios, not identified historical corrections.

## M5–M6: configuration and playback sensitivities

The current comparison fits ordinary negative-binomial models to the same positive-catch dates with documented operation and playback status in the two stable post-transition bush-net periods. M4 has weather and a smooth year term, M5 adds a fixed back/front period, and M6 adds nocturnal playback:

`catch ~ smooth_year + season_curve + moon + mist + rain + supported_weather + bush_period + nocturnal_playback`

The back/front coefficient is assumption-dependent because bush position changed with year. Its smooth-year interval spans no difference, and adding it slightly worsens held-out prediction. Daily net use is checked against weather and shown descriptively. Avoid extrapolating playback coefficients into later lighting or habitat conditions without a sensitivity analysis.

Do not create an operating-day sample by mixing all positive dates with selectively documented zeros: the observation rule would depend on catch outcome. The pipeline therefore retains only the positive-catch input and the independently documented-operation sensitivity input.

A later operation-day model could include confirmed zeroes after checking count completeness across all independently documented operated dates. A hurdle model can eventually separate `Pr(catch > 0 | operated)` from positive-catch intensity. It is not the first choice with only 20 candidate zeros and such uneven historical zero coverage. Do not estimate operation probability over all calendar dates until attendance/non-attendance is independently documented.

If complete net-metres × hours become available, assess a log-effort offset within comparable capture methods. It assumes proportional expected catch with effort; catch-triggered closure and saturation may violate that assumption. Keep hand captures separate from net capture effort. Model night and dawn counts separately only where capture method/timing supports that split; processing timestamps alone may be misleading.

## Validation and annual summaries

1. The implemented season-block validation refits the mist-calibration model inside each outer fold and averages predictions across repeated mist-state imputations.
2. Use blocked sessions/dates within seasons for daily prediction with annual effects. Use held-out seasons for transferability, with an explicit rule for an unseen year's effect; the current CV omits annual effects and therefore evaluates a different prediction task. Also check transfer across historical periods.
3. Compare predictive log scores, interval coverage and performance on extreme catches as well as log-scale errors. Inspect residual dependence within consecutive observed days; do not treat observations separated by long gaps as adjacent nights.
4. Assess concurvity among weather and mist terms, seasonal-window overlap and dependence of operational coefficients on individual seasons. Review three-state calibration by era and observation class.
5. Standardize to a fixed, documented joint distribution of date and weather with adequate support in the compared years. The current random sample of 500 positive dates is reproducible but weights frequently sampled conditions; use an explicit reference and report unsupported years. Standardize operational states only where those states are observed sufficiently often.
6. The annual index now pools coefficient and mist-state imputation uncertainty. Within-season session/block resampling and historical-operation uncertainty still require separate treatment, especially for sparse seasons.

The immediate deliverables should be a corrected positive-catch index, an audited documented-operation model, and a sensitivity comparison across disruption exclusions, exact staffing records, mist measurement and historical configurations. Historical abundance remains inseparable from unmeasured catchability without additional effort records or independent information.
