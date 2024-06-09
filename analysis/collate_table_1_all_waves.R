# # # # # # # # # # # # # # # # # # # # #
# Collate table 1 subgroup outputs to simplify output checking and release
# # # # # # # # # # # # # # # # # # # # #

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)


# Import table 1 by wave
collated = rbind(
  read_csv(here::here("output", "table_1", "table_1_wavejn1_collated.csv")) %>% mutate(wave = "wavejn1"),
  read_csv(here::here("output", "table_1", "table_1_wave4_collated.csv")) %>% mutate(wave = "wave4"),
  read_csv(here::here("output", "table_1", "table_1_wave3_collated.csv")) %>% mutate(wave = "wave3"),
  read_csv(here::here("output", "table_1", "table_1_wave2_collated.csv")) %>% mutate(wave = "wave2"),
  read_csv(here::here("output", "table_1", "table_1_wave1_collated.csv")) %>% mutate(wave = "wave1")
) %>% 
  relocate(wave)

# Save as html/rds
output_dir <- here("output", "table_1")
fs::dir_create(output_dir)
write_csv(collated, here::here("output", "table_1",  paste0("table_1_collated_all_waves.csv")))
