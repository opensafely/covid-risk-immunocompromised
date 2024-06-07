## ###########################################################

##  This script:
## - Contains a function that renames the subgroups to names
## visible in the manuscript

## Adapted from https://github.com/opensafely/covid_mortality_over_time
## Original script by: linda.nab@thedatalab.com - 20220608
## Updates by: edward.parker@lshtm.ac.uk
## ###########################################################

# Load libraries & functions ---
library(dplyr)

# Function ---
## Function 'rename_subgroups'
## Arguments:
## table: table with column 'subgroup' equal to subgroups in config.yaml
## output:
## table with column 'subgroup' that is renamed 
## (e.g., agegroup = Age Group etc.)
rename_subgroups <- function(table){
  table <- 
    table %>%
    mutate(
      subgroup = case_when(
        subgroup == "N" ~ "N",
        
        # Demography
        subgroup == "agegroup" ~ "Age Group",
        subgroup == "sex" ~ "Sex",
        subgroup == "ethnicity" ~ "Ethnicity",
        subgroup == "region" ~ "Region",
        subgroup == "imd" ~ "IMD quintile",
        subgroup == "care_home" ~ "Care home",
        subgroup == "smoking_status_comb" ~ "Smoking status",
        
        # Vaccine/Infection
        subgroup == "n_doses_wave" ~ "N prior doses",
        subgroup == "pre_wave_vaccine_group" ~ "Timing of last dose",
        subgroup == "pre_wave_infection_group" ~ "Prior infection status",
        subgroup == "pre_wave_vax_infection_comb" ~ "Vaccination/infection status",
        subgroup == "pre_wave_vax_infection_comb_narrow" ~ "Vaccination/infection status (narrow)",
        
        # Immunosuppression
        subgroup == "imm_subgroup" ~ "Immunosuppression subgroup",
        subgroup == "any_transplant_type" ~ "Organ transplant (type)",
        subgroup == "any_transplant_cat" ~ "Organ transplant (timing)",
        subgroup == "any_bone_marrow_type" ~ "HC or Tx (BM) (type)",
        subgroup == "any_bone_marrow_cat" ~ "HC or Tx (BM) (timing)",
        subgroup == "radio_chemo_cat" ~ "Radiotherapy/Chemotherapy",
        subgroup == "immunosuppression_medication_cat" ~ "Immunosuppression (medication)",
        subgroup == "immunosuppression_diagnosis_cat" ~ "Immunosuppression (diagnosis)",
        
        # Immunosuppression (binary)
        subgroup == "any_transplant" ~ "Organ transplant",
        subgroup == "any_bone_marrow" ~ "HC or Tx (BM)",
        subgroup == "radio_chemo" ~ "Radiotherapy/Chemotherapy",
        subgroup == "immunosuppression_medication" ~ "Immunosuppression (medication)",
        subgroup == "immunosuppression_diagnosis" ~ "Immunosuppression (diagnosis)",
        
        # At risk morbidity count
        subgroup == "multimorb_cat" ~ "Comorbidity count",
        
        # Comorbidities (multiple levels)
        subgroup == "bmi" ~ "Body Mass Index",
        subgroup == "asthma" ~ "Asthma",
        subgroup == "diabetes_controlled" ~ "Diabetes",
        subgroup == "ckd_rrt" ~ "Chronic kidney disease or renal replacement therapy",
        
        # Other clinical risk groups
        subgroup == "bp_ht" ~ "Other clinical risk group",
        subgroup == "chronic_respiratory_disease" ~ "Other clinical risk group",
        subgroup == "chronic_cardiac_disease" ~ "Other clinical risk group",
        subgroup == "cancer" ~ "Other clinical risk group",
        subgroup == "chronic_liver_disease" ~ "Other clinical risk group",
        subgroup == "stroke" ~ "Other clinical risk group",
        subgroup == "dementia" ~ "Other clinical risk group",
        subgroup == "other_neuro" ~ "Other clinical risk group",
        subgroup == "asplenia" ~ "Other clinical risk group",
        subgroup == "ra_sle_psoriasis" ~ "Other clinical risk group",
        subgroup == "learning_disability" ~ "Other clinical risk group",
        subgroup == "sev_mental_ill" ~ "Other clinical risk group",
    ),
    level = case_when(
      # Comorbidities
      level == "bp_ht" ~ "Hypertension",
      level == "chronic_respiratory_disease" ~ "Chronic respiratory disease",
      level == "chronic_cardiac_disease" ~ "Chronic cardiac disease",
      level == "cancer" ~ "Cancer (non haematological)",
      level == "chronic_liver_disease" ~ "Chronic liver disease",
      level == "stroke" ~ "Stroke",
      level == "dementia" ~ "Dementia",
      level == "other_neuro" ~ "Other neurological disease",
      level == "asplenia" ~ "Asplenia",
      level == "ra_sle_psoriasis" ~ "Rheumatoid arthritis/ lupus/ psoriasis",
      level == "learning_disability" ~ "Learning disability",
      level == "sev_mental_ill" ~ "Severe mental illness",
      TRUE ~ level
    ),
    
    )
}
