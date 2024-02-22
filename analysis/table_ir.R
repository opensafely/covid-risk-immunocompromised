# # # # # # # # # # # # # # # # # # # # #
# This script creates a table of incidence rates for different population subgroups
# # # # # # # # # # # # # # # # # # # # #

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)
library(survival)
library(gt)
library(gtsummary)
library(scales)
library(lubridate)

# Load custom functions
utils_dir <- here("analysis", "utils")
source(paste0(utils_dir, "/calc_ir.R")) # functions to define vaccine groups

# Select wave and subgroup based on input arguments
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  wave <- "wave4"
  subgroup <- "Tx"
} else {
  wave <- args[[1]]
  subgroup <- args[[2]]
}

# Set rounding (TRUE/FALSE) and threshold
round_logical = TRUE
round_threshold = 5
redaction_threshold = 10

# Import filtered data
data_filtered <- read_rds(here::here("output", "filtered", paste0("input_",wave,".rds"))) %>%
  mutate(
    N = 1,
  ) 

## Select subset
data_filtered = subset(data_filtered, imm_subgroup==subgroup)

# create list of covariates
subgroups_vctr <- c("N",
        # Demographics
         "agegroup", "sex", "ethnicity", "region", "imd", "care_home",
         # Immunosuppression (full)
         "any_transplant_type", "any_transplant_cat", "any_bone_marrow_type", "any_bone_marrow_cat", "radio_chemo_cat", "immunosuppression_medication_cat", "immunosuppression_diagnosis_cat", 
         # Immunosuppression (binary)
         "any_transplant", "any_bone_marrow", "radio_chemo", "immunosuppression_medication", "immunosuppression_diagnosis", 
         # Vaccination
         "n_doses_wave", "pre_wave_vaccine_group",
         # Prior infection group
         "pre_wave_infection_group",
         # Prior infection/vaccination
         "pre_wave_vax_infection_comb",
         # At risk morbidity count
         "multimorb_cat",
         # Risk group (clinical)
         "bmi", "asthma", "diabetes_controlled", "ckd_rrt", "bp_ht", "chronic_respiratory_disease", "chronic_cardiac_disease",
         "cancer", "chronic_liver_disease", "stroke", "dementia", "other_neuro", "asplenia",
         "ra_sle_psoriasis", "learning_disability", "sev_mental_ill"
  )

# Retain detailed immunosuppression variable for all data or specific subset, otherwise retain binary variable
if (subgroup=="Tx") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_bone_marrow_type", "any_bone_marrow_cat", "radio_chemo_cat", "immunosuppression_medication_cat", "immunosuppression_diagnosis_cat", 
                                                         "any_transplant")]
}
if (subgroup=="HC") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_type", "any_transplant_cat", "radio_chemo_cat", "immunosuppression_medication_cat", "immunosuppression_diagnosis_cat", 
                                                         "any_transplant", "any_bone_marrow")]
}
if (subgroup=="RC") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_type", "any_transplant_cat", "any_bone_marrow_type", "any_bone_marrow_cat", "immunosuppression_medication_cat", "immunosuppression_diagnosis_cat",  
                                                         "any_transplant", "any_bone_marrow", "radio_chemo")]
} 
if (subgroup=="IMM") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_type", "any_transplant_cat", "any_bone_marrow_type", "any_bone_marrow_cat", "radio_chemo_cat", "immunosuppression_diagnosis_cat",  
                                                         "any_transplant", "any_bone_marrow", "radio_chemo", "immunosuppression_medication")]
}
if (subgroup=="IMD") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_type", "any_transplant_cat", "any_bone_marrow_type", "any_bone_marrow_cat", "radio_chemo_cat", "immunosuppression_medication_cat", 
                                                         "any_transplant", "any_bone_marrow", "radio_chemo", "immunosuppression_medication", "immunosuppression_diagnosis")]
}



# Use loop to calculate incidence rates in each subgroup
outcomes = c("severe", "death", "severe_sens")
fup_groups = c("fup_severe", "fup_death", "fup_severe_sens")
ind_groups = c("ind_severe", "ind_death", "ind_severe_sens")

for (o in 1:length(outcomes)) {
  for (s in 1:length(subgroups_vctr)) {
    data_filtered = data_filtered %>% mutate(group = get(subgroups_vctr[s]))
    group = subgroups_vctr[s]
    ir_crude = data_filtered %>%
      group_by(group) %>%
      summarise(
        n = plyr::round_any(length(patient_id), 5),
        events = plyr::round_any(sum(get(ind_groups[o])),5),
        time = plyr::round_any(sum(as.numeric(get(fup_groups[o]))),5),
        calc_ir(events, time),
      )
    
    # Apply redactions
    for (i in 1:nrow(ir_crude)) {
      if (as.numeric(ir_crude$events[i])>0 & as.numeric(ir_crude$events[i])<=redaction_threshold) { ir_crude[i,c("events", "time", "ir", "ir_lower_ci", "ir_upper_ci")] = NA }
      if (as.numeric(ir_crude$n[i])>0 & as.numeric(ir_crude$n[i])<=redaction_threshold) { ir_crude[i,c("n", "events", "time", "ir", "ir_lower_ci", "ir_upper_ci")] = NA }
    }
    
    # If only 2 groups and one redacted, redact and flag as ineligible for models
    ir_crude$eligible = "yes"
    ngroup = nrow(ir_crude)
    
    if( any(is.na(ir_crude$events)) & (ngroup==2)) {
      ir_crude[,c("events", "time", "ir", "ir_lower_ci", "ir_upper_ci")] = NA
      ir_crude$eligible = "no"
    }
    if (ngroup==1) {  ir_crude$eligible = "no" }
    
    ir_crude$variable = subgroups_vctr[s]
    ir_crude$outcome = outcomes[o]
    if(s==1 & o==1) { ir_collated = ir_crude } else { ir_collated = rbind(ir_collated, ir_crude) }
  }
}

# Reorder columns
ir_collated = ir_collated %>% relocate(variable,outcome)


# Save output
output_dir <- here("output", "table_ir")
fs::dir_create(output_dir)
write_csv(ir_collated, here::here("output", "table_ir",  paste0("table_ir_",wave,"_",subgroup,".csv")))
