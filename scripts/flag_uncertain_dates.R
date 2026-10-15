# Flags sampling dates that are known or suspected to be wrong, so users of
# data/data.rds and data/data.csv who need the full date are warned. The dates
# themselves are left unchanged because the true dates are unknown; the
# sampling YEAR is correct for every record. The analyses in this repository
# use year only and are not affected.
#
# - 08 June 2006: before the start of the hunting season (02 July); confirmed
#   by J-KJ as a data-entry error, true date unknown.
# - 05 July 1998 and 10 July 2005: Sundays, when there was no puffin hunting.
#
# Adds two columns: date_uncertain (TRUE/FALSE) and date_note (reason, NA if
# not flagged). Safe to rerun. Run from the scripts/ folder.
library(dplyr)
library(readr)

data_all <- read_rds("../data/data.rds") |>
  select(-any_of(c("date_uncertain", "date_note")))

day <- as.Date(data_all$date)

data_all <- data_all |>
  mutate(
    date_note = case_when(
      day == as.Date("2006-06-08") ~ paste(
        "Uncertain date: before the start of the hunting season (02 July);",
        "confirmed data-entry error, true date unknown. Sampling year is correct."),
      day %in% as.Date(c("1998-07-05", "2005-07-10")) ~ paste(
        "Uncertain date: a Sunday, when there was no puffin hunting.",
        "Sampling year is correct."),
      .default = NA_character_
    ),
    date_uncertain = !is.na(date_note),
    .after = date
  ) |>
  relocate(date_note, .after = date_uncertain)

write_rds(data_all, "../data/data.rds")
write_csv(data_all, "../data/data.csv")

data_all |>
  filter(date_uncertain) |>
  count(date = as.Date(date), date_note) |>
  print()
