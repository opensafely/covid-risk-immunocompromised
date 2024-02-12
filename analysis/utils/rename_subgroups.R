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
        subgroup == "bmi" ~ "Body Mass Index",
        subgroup == "smoking_status_comb" ~ "Smoking status",
        
        # Vaccine/Infection
        subgroup == "n_doses_omicron" ~ "N prior doses",
        subgroup == "pre_omicron_vaccine_group" ~ "Timing of last dose",
        subgroup == "pre_omicron_infection_group" ~ "Prior infection status",
        
        # Immunosuppression
        subgroup == "organ_transplant_cat" ~ "Organ transplant",
        subgroup == "bone_marrow_transplant_cat" ~ "Bone marrow transplant",
        subgroup == "haem_cancer_cat" ~ "Haematological malignancy",
        subgroup == "immunosuppression_diagnosis_cat" ~ "Immunosuppression (diagnosis)",
        subgroup == "immunosuppression_medication_cat" ~ "Immunosuppression (medication)",
        subgroup == "immunosuppression_admin_cat" ~ "Immunosuppression (admin)",
        subgroup == "radio_chemo_cat" ~ "Radiotherapy/Chemotherapy",
        
        # At risk morbidity count
        subgroup == "multimorb_cat" ~ "Comorbidity count",
        
        # Comorbidities (multiple levels)
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
