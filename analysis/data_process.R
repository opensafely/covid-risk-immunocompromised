## ###########################################################

##  This script:
##  - Imports data extracted from the cohort extractor (wave1, wave2, wave3)
##  - Formats column types and levels of factors in data
##  - Saves processed data in ./output/processed/input_wave*.rds

## ###########################################################

# Load libraries
library(here)
library(dplyr)
library(readr)
library(purrr)
library(stringr)
library(tidyverse)

# Load custom functions
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/extract_data.R")) # function extract_data()
source(paste0(utils_dir, "/kidney_functions.R")) # function add_kidney_vars_to_data()
source(paste0(utils_dir, "/process_data.R")) # function process_data()
source(paste0(utils_dir, "/vaccine_vars.R")) # functions to define vaccine groups

# Print session info to metadata log file
sessionInfo()

# Load json config for dates of waves
config <- fromJSON(here("analysis", "config.json"))

# Import data extracts of waves ---
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  wave <- "wave4"
} else {
  wave <- args[[1]]
}

# Load data ---
# Find input file names by globbing
input_files <- Sys.glob(here("output", "input_wave*.csv.gz"))

# Find input file name for selected wave
input_file_wave <- input_files[str_detect(input_files, wave)]

# Extract data from the input_files and formats columns to correct type 
# (e.g., integer, logical etc)
data_extracted <- extract_data(file_name = input_file_wave)

## Add kidney columns to data (egfr and ckd_rrt)
data_extracted_with_kidney_vars <- add_kidney_vars_to_data(data_extracted = data_extracted)

## Process data to use correct factor levels and create prior infection variables
data_processed <- process_data(data_extracted_with_kidney_vars)
 
## Process data_extracted to add vaccination groups
data_processed <- data_processed %>%
  add_n_doses() %>%
  last_dose_pre_era(era="delta") %>%
  last_dose_pre_era(era="omcicron") %>%
  first_dose_post_era(era="alpha") %>%
  first_dose_post_era(era="delta") %>%
  first_dose_post_era(era="omicron") 

## Select final variables of interest
final_var_list <- c(config$demographic_vars, config$immunosuppression_vars, config$comorbidity_vars,
  config$era_infection_vars, config$vaccination_vars, config$outcome_vars)

## List variables being dropped
names(data_processed)[!names(data_processed) %in% final_var_list]

## Select final variables
data_processed_reduced <- data_processed %>%
  select(all_of(final_var_list)) %>%
  relocate(final_var_list)

# Save output ---
output_dir <- here("output", "processed")
fs::dir_create(output_dir)

## Save compressed RDS
saveRDS(object = data_processed_reduced, file = paste0(output_dir, "/input_", wave, ".rds"), compress = TRUE)

## Save csv for local visualisation
#write_csv(data_processed_reduced, file = paste0(output_dir, "/input_", wave, ".csv"))
#write_csv(data_processed, file = paste0(output_dir, "/input_", wave, "_full.csv"))
