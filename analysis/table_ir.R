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
  subgroup <- "transplant"
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
if (subgroup=="transplant") {
  data_filtered = subset(data_filtered, organ_transplant==1 | bone_marrow_transplant==1)
} else if (subgroup=="haem_cancer") {
  data_filtered = subset(data_filtered, haem_cancer==1)
} else if (subgroup=="imd") {
  data_filtered = subset(data_filtered, immunosuppression_diagnosis==1)
} else if (subgroup=="imm") {
  data_filtered = subset(data_filtered, immunosuppression_medication==1)
} else if (subgroup=="radio_chemo") {
  data_filtered = subset(data_filtered, radio_chemo==1)
} else {
  stop ("Arguments not specified correctly.")
}

# create list of covariates
subgroups_vctr <- c("N",
        # Demographics
         "agegroup", "sex", "ethnicity", "region", "imd", "care_home",
         # Immunosuppression (full)
         "any_transplant_cat_broad", "haem_cancer_cat", "immunosuppression_diagnosis_cat", "immunosuppression_medication_cat", "radio_chemo_cat",
         # Immunosuppression (binary)
         "any_transplant", "haem_cancer", "immunosuppression_diagnosis", "immunosuppression_medication", "radio_chemo",
         # Vaccination
         "n_doses_wave", "pre_wave_vaccine_group",
         # Prior infection group
         "pre_wave_infection_group",
         ## At risk morbidity count
         "multimorb_cat",
         ## Risk group (clinical)
         "bmi", "asthma", "diabetes_controlled", "ckd_rrt", "bp_ht", "chronic_respiratory_disease", "chronic_cardiac_disease",
         "cancer", "chronic_liver_disease", "stroke", "dementia", "other_neuro", "asplenia",
         "ra_sle_psoriasis", "learning_disability", "sev_mental_ill"
  )

# Retain detailed immunosuppression variable for all data or specific subset, otherwise retain binary variable
if (subgroup=="transplant") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("haem_cancer_cat", "immunosuppression_diagnosis_cat", "immunosuppression_medication_cat", "radio_chemo_cat", "any_transplant")]
}
if (subgroup=="haem_cancer") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_cat_broad", "immunosuppression_diagnosis_cat", "immunosuppression_medication_cat", "radio_chemo_cat", "haem_cancer")]
}
if (subgroup=="imd") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_cat_broad", "haem_cancer_cat", "immunosuppression_medication_cat", "radio_chemo_cat", "immunosuppression_diagnosis")]
}
if (subgroup=="imm") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_cat_broad", "haem_cancer_cat", "immunosuppression_diagnosis_cat", "radio_chemo_cat", "immunosuppression_medication")]
}
if (subgroup=="radio_chemo") {
  subgroups_vctr = subgroups_vctr[!subgroups_vctr %in% c("any_transplant_cat_broad", "haem_cancer_cat", "immunosuppression_diagnosis_cat", "immunosuppression_medication_cat", "radio_chemo")]
} 

# Use loop to calculate incidence rates in each subgroup
outcomes = c("severe", "death", "severe_sens", "death_sens")
fup_groups = c("fup_severe", "fup_death", "fup_severe_sens", "fup_death_sens")
ind_groups = c("ind_severe", "ind_death", "ind_severe_sens", "ind_death_sens")

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
    ir_crude$variable = subgroups_vctr[s]
    ir_crude$outcome = outcomes[o]
    if(s==1 & o==1) { ir_collated = ir_crude } else { ir_collated = rbind(ir_collated, ir_crude) }
  }
}

# Reorder columns
ir_collated = ir_collated %>% relocate(variable,outcome)

# Apply redactions
for (i in 1:nrow(ir_collated)) {
  if (as.numeric(ir_collated$events[i])>0 & as.numeric(ir_collated$events[i])<=redaction_threshold) { ir_collated[i,c("events", "time", "ir", "ir_lower_ci", "ir_upper_ci")] = NA }
  if (as.numeric(ir_collated$n[i])>0 & as.numeric(ir_collated$n[i])<=redaction_threshold) { ir_collated[i,c("n", "events", "time", "ir", "ir_lower_ci", "ir_upper_ci")] = NA }
}

# Save output
output_dir <- here("output", "table_ir")
fs::dir_create(output_dir)
write_csv(ir_collated, here::here("output", "table_ir",  paste0("table_ir_",wave,"_",subgroup,".csv")))
