# # # # # # # # # # # # # # # # # # # # #
# Collate table of ir/hr subgroup outputs to simplify output checking and release
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

# Import ir/hr outputs
collated = rbind(
  read_csv(here::here("output", "table_ir_hr", paste0("table_ir_hr_",wave,"_Tx_simple.csv"))) %>% mutate(subset = "Tx"),
  read_csv(here::here("output", "table_ir_hr", paste0("table_ir_hr_",wave,"_HC_simple.csv"))) %>% mutate(subset = "HC"),
  read_csv(here::here("output", "table_ir_hr", paste0("table_ir_hr_",wave,"_RC_simple.csv"))) %>% mutate(subset = "RC"),
  read_csv(here::here("output", "table_ir_hr", paste0("table_ir_hr_",wave,"_IMM_simple.csv"))) %>% mutate(subset = "IMM"),
  read_csv(here::here("output", "table_ir_hr", paste0("table_ir_hr_",wave,"_IMD_simple.csv"))) %>% mutate(subset = "IMD")
) %>% 
  relocate(subset)

# Save as html/rds
output_dir <- here("output", "table_ir_hr")
fs::dir_create(output_dir)
write_csv(collated, here::here("output", "table_ir_hr",  paste0("table_ir_hr_",wave,"_collated.csv")))
