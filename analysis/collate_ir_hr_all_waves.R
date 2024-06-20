# # # # # # # # # # # # # # # # # # # # #
# Collate table of ir/hr subgroup outputs to simplify output checking and release
# # # # # # # # # # # # # # # # # # # # #

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)


# Import ir/hr outputs
collated = rbind(
  read_csv(here::here("output", "table_ir_hr", "table_ir_hr_wavejn1_collated.csv")) %>% mutate(wave = "wavejn1"),
  read_csv(here::here("output", "table_ir_hr", "table_ir_hr_wave4_collated.csv")) %>% mutate(wave = "wave4"),
  read_csv(here::here("output", "table_ir_hr", "table_ir_hr_wave3_collated.csv")) %>% mutate(wave = "wave3"),
  read_csv(here::here("output", "table_ir_hr", "table_ir_hr_wave2_collated.csv")) %>% mutate(wave = "wave2"),
  read_csv(here::here("output", "table_ir_hr", "table_ir_hr_wave1_collated.csv")) %>% mutate(wave = "wave1")
) %>% 
  relocate(wave)

# Save as html/rds
output_dir <- here("output", "collated")
fs::dir_create(output_dir)
write_csv(collated, here::here("output", "collated",  paste0("table_ir_hr_collated_all_waves.csv")))
