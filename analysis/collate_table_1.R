# # # # # # # # # # # # # # # # # # # # #
# Collate table 1 subgroup outputs to simplify output checking and release
# # # # # # # # # # # # # # # # # # # # #

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)

# Select wave and subgroup based on input arguments
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  wave <- "wave4"
} else {
  wave <- args[[1]]
}

# Import table 1 by subgroup
collated = rbind(
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_all.rds"))) %>% mutate(subset = "all"),
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_Tx.rds"))) %>% mutate(subset = "Tx"),
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_HC.rds"))) %>% mutate(subset = "HC"),
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_RC.rds"))) %>% mutate(subset = "RC"),
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_IMM.rds"))) %>% mutate(subset = "IMM"),
  read_rds(here::here("output", "table_1", paste0("table_1_",wave,"_IMD.rds"))) %>% mutate(subset = "IMD")
)

# Save as html/rds
output_dir <- here("output", "table_1")
fs::dir_create(output_dir)
write_csv(collated, here::here("output", "table_1",  paste0("table_1_",wave,"_collated.csv")))
