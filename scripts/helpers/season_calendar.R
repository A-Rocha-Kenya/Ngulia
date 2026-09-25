# Shared October–January scaffold; source observations may extend January.
build_season_dates <- function(..., seasons = 1969:2023) {
  season_bounds <- bind_rows(...) |>
    filter(!is.na(date), !is.na(season)) |>
    distinct(season, date) |>
    group_by(season) |>
    summarise(
      max_date = max(date),
      .groups = "drop"
    )

  default_bounds <- tibble(season = as.integer(seasons)) |>
    mutate(
      default_min_date = make_date(season, 10L, 20L),
      default_max_date = make_date(season + 1L, 1L, 12L)
    ) |>
    left_join(season_bounds, by = "season") |>
    mutate(
      min_date = default_min_date,
      max_date = case_when(
        !is.na(max_date) & month(max_date) <= 1L ~ pmax(default_max_date, max_date),
        TRUE ~ default_max_date
      )
    ) |>
    arrange(season)

  bind_rows(lapply(seq_len(nrow(default_bounds)), function(i) {
    tibble(
      date = seq(default_bounds$min_date[[i]], default_bounds$max_date[[i]], by = "1 day"),
      season = default_bounds$season[[i]]
    )
  }))
}
