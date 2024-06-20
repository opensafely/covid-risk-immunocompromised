# # # # # # # # # # # # # # # # # # # # #
# Collate flow diagrams to simplify output checking and release
# # # # # # # # # # # # # # # # # # # # #

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)


# Import table 1 by wave
collated = rbind(
  read_csv(here::here("output", "flowchart", "flowchart_wavejn1.csv")) %>% mutate(wave = "wavejn1"),
  read_csv(here::here("output", "flowchart", "flowchart_wave4.csv")) %>% mutate(wave = "wave4"),
  read_csv(here::here("output", "flowchart", "flowchart_wave3.csv")) %>% mutate(wave = "wave3"),
  read_csv(here::here("output", "flowchart", "flowchart_wave2.csv")) %>% mutate(wave = "wave2"),
  read_csv(here::here("output", "flowchart", "flowchart_wave1.csv")) %>% mutate(wave = "wave1")
) %>%
  relocate(wave) %>%
  select(wave,criteria,n) %>%
  mutate(n = plyr::round_any(n, 5))

# Save as html/rds
output_dir <- here("output", "collated")
fs::dir_create(output_dir)
write_csv(collated, here::here("output", "collated",  paste0("flowchart_collated_all_waves.csv")))
