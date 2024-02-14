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
source(paste0(utils_dir, "/define_vars.R")) # function define_vars()
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

# Specify index date
if (wave=="wave1") { index_date <- config$wave1$start_date }
if (wave=="wave2") { index_date <- config$wave2$start_date }
if (wave=="wave3") { index_date <- config$wave3$start_date }
if (wave=="wave4") { index_date <- config$wave4$start_date }

# Load data ---
# Find input file names by globbing
input_files <- Sys.glob(here("output", "input_wave*.csv.gz"))

# Find input file name for selected wave
input_file_wave <- input_files[str_detect(input_files, wave)]

# Extract data from the input_files and formats columns to correct type 
# (e.g., integer, logical etc)
data_extracted <- extract_data(file_name = input_file_wave) %>%
  mutate(index_date = as.Date(index_date, format = "%Y-%m-%d"))

## Add kidney columns to data (egfr and ckd_rrt)
data_extracted_with_kidney_vars <- add_kidney_vars_to_data(data_extracted = data_extracted)

## Process data to use correct factor levels and create prior infection variables
data_processed <- process_data(data_extracted_with_kidney_vars)
 
## Process data_processed to add vaccination groups
data_processed <- data_processed %>%
  add_n_doses() %>%
  last_dose_pre_era(era="delta") %>%
  last_dose_pre_era(era="omicron") %>%
  first_dose_post_era(era="alpha") %>%
  first_dose_post_era(era="delta") %>%
  first_dose_post_era(era="omicron") 

## Set wave-specific start/stop/censor dates
if (wave=="wave1") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = wt_start_date,
      wave_end_date = wt_end_date,
      wave_covid_cat = wt_covid_cat,
      wave_covid_max_date = wt_covid_max_date,
      pre_wave_infection_group = "No prior infection",
      pre_wave_infection_days = NA,
      n_doses_wave = 0,
      pre_wave_vaccine_group = "Unvaccinated",
      pre_wave_last_vax_date = NA,
      pre_wave_vax_diff = NA,
      next_vax_date = NA
    )
}
if (wave=="wave2") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = alpha_start_date,
      wave_end_date = alpha_end_date,
      wave_covid_cat = alpha_covid_cat,
      wave_covid_max_date = alpha_covid_max_date,
      pre_wave_infection_group = pre_alpha_infection_group,
      pre_wave_infection_days = pre_alpha_infection_days,
      n_doses_wave = 0,
      pre_wave_vaccine_group = "Unvaccinated",
      pre_wave_last_vax_date = NA,
      pre_wave_vax_diff = NA,
      next_vax_date = post_alpha_first_vax_date
    )
}
if (wave=="wave3") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = delta_start_date,
      wave_end_date = delta_end_date,
      wave_covid_cat = delta_covid_cat,
      wave_covid_max_date = delta_covid_max_date,
      pre_wave_infection_group = pre_delta_infection_group,
      pre_wave_infection_days = pre_delta_infection_days,
      n_doses_wave = n_doses_delta,
      pre_wave_vaccine_group = pre_delta_vaccine_group,
      pre_wave_last_vax_date = pre_delta_last_vax_date,
      pre_wave_vax_diff = pre_delta_vax_diff,
      next_vax_date = post_delta_first_vax_date
    )
}
if (wave=="wave4") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = omicron_start_date,
      wave_end_date = omicron_end_date,
      wave_covid_cat = as.numeric(!is.na(omicron_positive_test_date)),
      wave_covid_max_date = omicron_positive_test_date,
      pre_wave_infection_group = pre_omicron_infection_group,
      pre_wave_infection_days = pre_omicron_infection_days,
      n_doses_wave = n_doses_omicron,
      pre_wave_vaccine_group = pre_omicron_vaccine_group,
      pre_wave_last_vax_date = pre_omicron_last_vax_date,
      pre_wave_vax_diff = pre_omicron_vax_diff,
      next_vax_date = post_omicron_first_vax_date
    )
}

# Calculate follow-up time and index values
data_processed = data_processed %>%
  mutate(
    # calculate tte
    tte_stop_severe_date = pmin(covid_severe_date, covid_death_date, died_any_date, dereg_date, wave_end_date, na.rm=TRUE),
    tte_stop_death_date = pmin(covid_death_date, died_any_date, dereg_date, wave_end_date, na.rm=TRUE),
    
    # follow-up time and ind values for primary analysis
    fup_severe = as.numeric(tte_stop_severe_date - wave_start_date),
    ind_severe = if_else((covid_severe_date>tte_stop_severe_date) | is.na(covid_severe_date), FALSE, TRUE),
    fup_death = as.numeric(tte_stop_death_date - wave_start_date),
    ind_death = if_else((covid_death_date>tte_stop_death_date) | is.na(covid_death_date), FALSE, TRUE),
    
    # calculate tte
    tte_stop_severe_sens = pmin(tte_stop_severe_date, next_vax_date, na.rm=TRUE),
    tte_stop_death_sens = pmin(tte_stop_death_date, next_vax_date, na.rm=TRUE),
    
    # follow-up time and ind values for primary analysis
    fup_severe_sens = as.numeric(tte_stop_severe_sens - wave_start_date),
    ind_severe_sens = if_else((covid_severe_date>tte_stop_severe_sens) | is.na(covid_severe_date), FALSE, TRUE),
    fup_death_sens = as.numeric(tte_stop_death_sens - wave_start_date),
    ind_death_sens = if_else((covid_death_date>tte_stop_death_sens) | is.na(covid_death_date), FALSE, TRUE)
  )


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
