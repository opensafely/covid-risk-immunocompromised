## ###########################################################

##  This script:
## - Contains a general function that is used to reformat data

## Adapted from https://github.com/opensafely/covid_mortality_over_time
## Original script by: linda.nab@thedatalab.com - 2022024
## Updates by: edward.parker@lshtm.ac.uk

## ###########################################################

# Load libraries & functions ---
library(dplyr)
library(here)
library(lubridate)
library(jsonlite)
library(readr)

# Function ---
## Extracts data and maps columns to the correct format (integer, factor etc)
## args:
## - file_name: string with the location of the input file extracted by the 
##   cohortextracter
## output:
## data.frame of the input file, with columns of the correct type
extract_data <- function(file_name) {
  ## read all data with default col_types 
  data_extracted <-
    read_csv(
      file_name,
      col_types = cols(
        patient_id = col_integer(),
        has_follow_up = col_logical(),
        
        # demographics
        age = col_integer(),
        agegroup = col_character(),
        agegroup_std = col_character(),
        sex = col_character(),
        ethnicity_primary = col_number(),
        ethnicity_sus = col_number(),
        ethnicity = col_number(),
        care_home_type =  col_character(),
        care_home_tpp = col_logical(),
        care_home_code = col_logical(),
        bmi_value = col_double(),
        bmi = col_character(),
        smoking_status_comb = col_character(),
        imd = col_number(),
        stp = col_character(),
        region = col_character(),
        
        # immunosuppression (binary)
        organ_transplant = col_logical(),
        bone_marrow_transplant = col_logical(),
        haem_cancer = col_logical(),
        immunosuppression_diagnosis = col_logical(),
        immunosuppression_medication = col_logical(),
        radio_chemo = col_logical(),
        
        # immunosuppression (dates)
        organ_transplant_date = col_date(format = "%Y-%m-%d"),
        bone_marrow_transplant_date = col_date(format = "%Y-%m-%d"),
        haem_cancer_date = col_date(format = "%Y-%m-%d"),
        immunosuppression_diagnosis_date = col_date(format = "%Y-%m-%d"),
        immunosuppression_medication_date = col_date(format = "%Y-%m-%d"),
        radio_chemo_date = col_date(format = "%Y-%m-%d"),
        
        # comorbidities (multilevel)
        asthma = col_number(),
        bp = col_number(),
        bp_ht = col_logical(),
        diabetes_controlled = col_number(),
        
        # ckd/rrt
        # dialysis or kidney transplant
        rrt_cat = col_number(),
        # calc of egfr
        creatinine = col_number(), 
        creatinine_operator = col_character(),
        creatinine_age = col_number(),

        # comorbidities (binary)
        hypertension = col_logical(),
        chronic_respiratory_disease = col_logical(),
        chronic_cardiac_disease = col_logical(),
        cancer = col_logical(),
        chronic_liver_disease = col_logical(),
        stroke = col_logical(),
        dementia = col_logical(),
        other_neuro = col_logical(),
        asplenia = col_logical(),
        ra_sle_psoriasis = col_logical(),
        learning_disability = col_logical(),
        sev_mental_ill = col_logical(),
        
        # vaccination dates
        covid_vax_date_1 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_2 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_3 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_4 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_5 = col_date(format = "%Y-%m-%d"),
        covid_vax_date_6 = col_date(format = "%Y-%m-%d"),
        
        # era exposures
        wt_positive_test_date = col_date(format = "%Y-%m-%d"),
        wt_primary_care_date = col_date(format = "%Y-%m-%d"),	
        wt_hospitalisation_date	= col_date(format = "%Y-%m-%d"),
        wt_emergency_date = col_date(format = "%Y-%m-%d"),	
        alpha_positive_test_date	= col_date(format = "%Y-%m-%d"),
        alpha_hospitalisation_date = col_date(format = "%Y-%m-%d"),	
        alpha_emergency_date = col_date(format = "%Y-%m-%d"),
        delta_positive_test_date = col_date(format = "%Y-%m-%d"),	
        delta_hospitalisation_date = col_date(format = "%Y-%m-%d"),
        delta_emergency_date = col_date(format = "%Y-%m-%d"),	
        omicron_positive_test_date = col_date(format = "%Y-%m-%d"),
        
        # outcomes (including censoring events)
        covid_hospitalisation_date = col_date(format = "%Y-%m-%d"),
        covid_emergency_date = col_date(format = "%Y-%m-%d"),
        covid_death_date = col_date(format = "%Y-%m-%d"),
        died_any_date = col_date(format = "%Y-%m-%d"),
        dereg_date = col_date(format = "%Y-%m-%d"),
        .default = col_skip()        
      ),   
      na = character() # more stable to convert to missing later
    ) %>%
    # add era start dates
    mutate(
      wt_start_date = as.Date("2020-03-23", format = "%Y-%m-%d"),
      alpha_start_date = as.Date("2020-09-07", format = "%Y-%m-%d"),
      delta_start_date = as.Date("2021-05-28", format = "%Y-%m-%d"),
      omicron_start_date = as.Date("2021-12-15", format = "%Y-%m-%d"),
    ) %>%
    # Floor dates to avoid timestamps causing inequalities for dates on the same day
    mutate(across(where(is.Date), 
                  ~ floor_date(
                    as.Date(.x, format="%Y-%m-%d"),
                    unit = "days"))) %>%
    # Filter to individuals with 3 months of follow-up at a single GP
    filter(has_follow_up == TRUE) %>%
    # Convert TRUE/FALSE to 1/0
    mutate(across(
      where(is.logical),
      ~.x*1L 
    )) %>%
  arrange(patient_id) 
    
  data_extracted
}
