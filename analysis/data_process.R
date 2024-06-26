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
  wave <- "wavejn1"
} else {
  wave <- args[[1]]
}

# Specify index date
if (wave=="wave1") { index_date <- config$wave1$start_date }
if (wave=="wave2") { index_date <- config$wave2$start_date }
if (wave=="wave3") { index_date <- config$wave3$start_date }
if (wave=="wave4") { index_date <- config$wave4$start_date }
if (wave=="wavejn1") { index_date <- config$wavejn1$start_date }

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
  last_dose_pre_era(era="jn1") %>%
  first_dose_post_era(era="alpha") %>%
  first_dose_post_era(era="delta") %>%
  first_dose_post_era(era="omicron") %>%
  first_dose_post_era(era="jn1")
  
## Set wave-specific start/stop/censor dates
if (wave=="wave1") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = wt_start_date,
      wave_end_date = wt_end_date,
      pre_wave_infection_group = "No prior infection",
      pre_wave_infection_days = NA,
      n_doses_wave = 0,
      pre_wave_vaccine_group = "Unvaccinated",
      pre_wave_last_vax_date = NA,
      pre_wave_vax_diff = NA,
      next_vax_date = NA,
      pre_wave_vax_infection_comb = NA,
      pre_wave_vax_infection_comb_narrow = NA
    )
}
if (wave=="wave2") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = alpha_start_date,
      wave_end_date = alpha_end_date,
      pre_wave_infection_group = pre_alpha_infection_group,
      pre_wave_infection_days = pre_alpha_infection_days,
      n_doses_wave = 0,
      pre_wave_vaccine_group = "Unvaccinated",
      pre_wave_last_vax_date = NA,
      pre_wave_vax_diff = NA,
      next_vax_date = post_alpha_first_vax_date,
      pre_wave_vax_infection_comb = NA,
      pre_wave_vax_infection_comb_narrow = NA
    )
}
if (wave=="wave3") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = delta_start_date,
      wave_end_date = delta_end_date,
      pre_wave_infection_group = pre_delta_infection_group,
      pre_wave_infection_days = pre_delta_infection_days,
      n_doses_wave = n_doses_delta,
      pre_wave_vaccine_group = pre_delta_vaccine_group,
      pre_wave_last_vax_date = pre_delta_last_vax_date,
      pre_wave_vax_diff = pre_delta_vax_diff,
      next_vax_date = post_delta_first_vax_date,
      pre_wave_vax_infection_comb = fct_case_when(
        pre_wave_vaccine_group=="Unvaccinated" & pre_wave_infection_group=="No prior infection" ~ "Unvaccinated, uninfected",
        pre_wave_vaccine_group=="Unvaccinated" & pre_wave_infection_group!="No prior infection" ~ "Unvaccinated, infected",
        pre_wave_vaccine_group=="27+ weeks" & pre_wave_infection_group=="No prior infection" ~ "27+ weeks, uninfected",
        pre_wave_vaccine_group=="27+ weeks" & pre_wave_infection_group!="No prior infection" ~ "27+ weeks, infected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group=="No prior infection" ~ "0-26 weeks, uninfected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group!="No prior infection" ~ "0-26 weeks, infected",
        TRUE ~ NA_character_
      ),
      pre_wave_vax_infection_comb_narrow = NA
    )
}
if (wave=="wave4") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = omicron_start_date,
      wave_end_date = omicron_end_date,
      pre_wave_infection_group = pre_omicron_infection_group,
      pre_wave_infection_days = pre_omicron_infection_days,
      n_doses_wave = n_doses_omicron,
      pre_wave_vaccine_group = pre_omicron_vaccine_group,
      pre_wave_last_vax_date = pre_omicron_last_vax_date,
      pre_wave_vax_diff = pre_omicron_vax_diff,
      next_vax_date = post_omicron_first_vax_date,
      pre_wave_vax_infection_comb = fct_case_when(
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group=="No prior infection" ~ "27+ weeks/unvax, uninfected",
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group!="No prior infection" ~ "27+ weeks/unvax, infected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group=="No prior infection" ~ "0-26 weeks, uninfected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group!="No prior infection" ~ "0-26 weeks, infected",
        TRUE ~ NA_character_
      ),
      pre_wave_vax_infection_comb_narrow = NA
    )
}
if (wave=="wavejn1") {
  data_processed = data_processed %>%
    mutate(
      wave_start_date = jn1_start_date,
      wave_end_date = jn1_end_date,
      pre_wave_infection_group = pre_jn1_infection_group,
      pre_wave_infection_days = pre_jn1_infection_days,
      n_doses_wave = n_doses_jn1,
      pre_wave_vaccine_group = pre_jn1_vaccine_group,
      pre_wave_last_vax_date = pre_jn1_last_vax_date,
      pre_wave_vax_diff = pre_jn1_vax_diff,
      next_vax_date = post_jn1_first_vax_date,
      pre_wave_vax_infection_comb = fct_case_when(
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group=="No prior infection" ~ "27+ weeks/unvax, uninfected",
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group!="No prior infection" ~ "27+ weeks/unvax, infected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group=="No prior infection" ~ "0-26 weeks, uninfected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group!="No prior infection" ~ "0-26 weeks, infected",
        TRUE ~ NA_character_
      ),
      pre_wave_vax_infection_comb_narrow = fct_case_when(
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group=="No prior infection" ~ "27+ weeks/unvax, uninfected",
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group=="Infected (Pre Omicron)" ~ "27+ weeks/unvax, Pre Omicron",
        pre_wave_vaccine_group=="27+ weeks/unvax" & pre_wave_infection_group %in% c("Infected (BA.1/BA.2)","Infected (BA.5/XBB)") ~ "27+ weeks/unvax, Omicron",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group=="No prior infection" ~ "0-26 weeks, uninfected",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group=="Infected (Pre Omicron)" ~ "0-26 weeks, Pre Omicron",
        pre_wave_vaccine_group %in% c("0-12 weeks", "13-26 weeks") & pre_wave_infection_group %in% c("Infected (BA.1/BA.2)","Infected (BA.5/XBB)") ~ "0-26 weeks, Omicron",
        TRUE ~ NA_character_
      )
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

    # follow-up time and ind values for primary analysis
    fup_severe_sens = as.numeric(tte_stop_severe_sens - wave_start_date),
    ind_severe_sens = if_else((covid_severe_date>tte_stop_severe_sens) | is.na(covid_severe_date), FALSE, TRUE),
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
