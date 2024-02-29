# # # # # # # # # # # # # # # # # # # # #
# This script creates a table of incidence rates and hazard ratios for different population subgroups
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
library(rms)

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
         "agegroup", "sex", "ethnicity", "region", "imd", "care_home","smoking_status_comb",
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

# loop for outcomes
for (o in 1:length(outcomes)) {
  
  # define generic follow-up times and indexes
  selected_outcome = outcomes[o]
  
  if (selected_outcome=="severe") {
    data_filtered = data_filtered %>% mutate(follow_up = fup_severe, ind = ind_severe)
  }
  if (selected_outcome=="death") {
    data_filtered = data_filtered %>% mutate(follow_up = fup_death, ind = ind_death)
  }
  if (selected_outcome=="severe_sens") {
    data_filtered = data_filtered %>% mutate(follow_up = fup_severe_sens, ind = ind_severe_sens)
  }
  
  # loop for variable subgroups
  for (s in 1:length(subgroups_vctr)) {
    
    # Assign selected variable as 'group' in filtered data 
    group = subgroups_vctr[s]
    data_filtered = data_filtered %>% mutate(group = get(subgroups_vctr[s]))
    
    # Calculate crude incidence rates for variable subgroups
    ir_crude = data_filtered %>%
      group_by(group) %>%
      summarise(
        n = plyr::round_any(length(patient_id), 5),
        events = plyr::round_any(sum(ind),5),
        time = plyr::round_any(sum(as.numeric(follow_up)),5),
        calc_ir(events, time)
      ) %>%
      mutate(
        group = as.character(group)
      )
    
    # Determine eligibility for cox models
    ## At least two groups above redaction threshold
    ## Exclude region as stratification factor
    if( group=="region" | (sum(ir_crude$events>redaction_threshold) < 2) ) { 
      ir_crude$eligible = "no" 
      } else {
      ir_crude$eligible = "yes"
      }
    
    # Model output columns
    model_cols = c("reference_row_min", "n_obs_min", "n_event_min", "exposure_min", "estimate_min", "std.error_min", "statistic_min", 
                   "p.value_min", "conf.low_min", "conf.high_min",
                   "n_obs_adj", "n_event_adj", "exposure_adj", "estimate_adj", "std.error_adj", "statistic_adj", 
                   "p.value_adj", "conf.low_adj", "conf.high_adj",
                   "n_obs_full", "n_event_full", "exposure_full", "estimate_full", "std.error_full", "statistic_full", 
                   "p.value_full", "conf.low_full", "conf.high_full")
    
    # If ineligible - assign model outputs as NA and skip variable
    if (ir_crude$eligible[1]=="no") {
      ir_crude[,model_cols] = NA
    
    # If eligible, proceed with minimal and adjusted models
    } else {
      
      # Fit minimally adjusted models (include rcs(age, 4) + sex)
      if (group == "agegroup") {
        cox_minimal = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(agegroup) + sex + strata(region)")), 
                            data = data_filtered)
      } else if (group == "sex") {
        cox_minimal = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + factor(sex) + strata(region)")), 
                            data = data_filtered)
      } else {
        cox_minimal = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + strata(region)")), 
                            data = data_filtered)
      }
      
      # Pick outputs for term of interest
      tidy = broom.helpers::tidy_plus_plus(cox_minimal, exponentiate = TRUE) 
      tidy = subset(tidy, variable==paste0("factor(",group,")")) %>% 
        rename(group = label) %>%
        mutate(
          group = as.character(group),
          n_obs = plyr::round_any(n_obs, 5), # used to cross check IR calculations
          n_event = plyr::round_any(n_event, 5),
          exposure = plyr::round_any(exposure, 5)
        ) %>%
      select(group, reference_row, n_obs, n_event, exposure, estimate, std.error, statistic, p.value, conf.low, conf.high)
      names(tidy)[2:ncol(tidy)] = paste0(names(tidy)[2:ncol(tidy)],"_min")
      
      # Merge with crude IRs
      ir_crude <- left_join(ir_crude, tidy, by = "group")
      
      # Fit modestly adjusted models (additionally include pre_wave_vaccine_group + pre_wave_infection_group)
      if (group == "agegroup") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(agegroup) + sex + pre_wave_vaccine_group + pre_wave_infection_group + strata(region)")), 
                         data = data_filtered)
        
      } else if (group == "sex") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + factor(sex) + pre_wave_vaccine_group + pre_wave_infection_group + strata(region)")), 
                         data = data_filtered)
        
      } else if (group == "pre_wave_vaccine_group" | group == "n_doses_wave") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_infection_group + strata(region)")), 
                         data = data_filtered)
        
      } else if (group == "pre_wave_infection_group") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_vaccine_group + strata(region)")), 
                         data = data_filtered)
        
      } else if (group == "pre_wave_vax_infection_comb") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + + rcs(age, 4) + sex + strata(region)")), 
                         data = data_filtered)
        
      } else {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_vaccine_group + pre_wave_infection_group + strata(region)")), 
                         data = data_filtered)
      }
      
      # Pick out adjusted outputs for term of interest
      tidy = broom.helpers::tidy_plus_plus(cox_adj, exponentiate = TRUE) 
      tidy = subset(tidy, variable==paste0("factor(",group,")")) %>% 
        rename(group = label) %>%
        mutate(
          group = as.character(group),
          n_obs = plyr::round_any(n_obs, 5), # used to cross check IR calculations
          n_event = plyr::round_any(n_event, 5),
          exposure = plyr::round_any(exposure, 5)
        ) %>%
        select(group, n_obs, n_event, exposure, estimate, std.error, statistic, p.value, conf.low, conf.high)
      names(tidy)[2:ncol(tidy)] = paste0(names(tidy)[2:ncol(tidy)],"_adj")
      
      # Merge with crude IRs
      ir_crude <- left_join(ir_crude, tidy, by = "group")
      
      # Fit fully adjusted models (additionally include ethnicity + imd + multimorb_cat)
      if (group == "agegroup") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(agegroup) + sex + pre_wave_vaccine_group + pre_wave_infection_group +
                                ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
        
      } else if (group == "sex") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + factor(sex) + pre_wave_vaccine_group + pre_wave_infection_group + 
                                          ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
      
      } else if (group == "ethnicity") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + sex + pre_wave_vaccine_group + pre_wave_infection_group + 
                                          factor(ethnicity) + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
       
      } else if (group == "imd") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + sex + pre_wave_vaccine_group + pre_wave_infection_group + 
                                          ethnicity + factor(imd) + multimorb_cat + strata(region)")), 
                        data = data_filtered)
      
      } else if (group == "multimorb_cat") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ rcs(age, 4) + sex + pre_wave_vaccine_group + pre_wave_infection_group + 
                                          ethnicity + imd + factor(multimorb_cat) + strata(region)")), 
                        data = data_filtered)
        
      } else if (group == "pre_wave_vaccine_group" | group == "n_doses_wave") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_infection_group + 
                                          ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
        
      } else if (group == "pre_wave_infection_group") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_vaccine_group + 
                                          ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
        
      } else if (group == "pre_wave_vax_infection_comb") {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + + rcs(age, 4) + sex + 
                                          ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
      
      } else if (group %in% c("care_home", "smoking_status_comb",
                              "any_transplant_type", "any_transplant_cat", "any_bone_marrow_type", "any_bone_marrow_cat", "radio_chemo_cat", "immunosuppression_medication_cat", "immunosuppression_diagnosis_cat", 
                              "any_transplant", "any_bone_marrow", "radio_chemo", "immunosuppression_medication", "immunosuppression_diagnosis")) {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + + rcs(age, 4) + sex + 
                                          ethnicity + imd + strata(region)")), 
                        data = data_filtered)
        
      } else {
        cox_adj = coxph(as.formula(paste0("Surv(follow_up, ind) ~ factor(",group,") + rcs(age, 4) + sex + pre_wave_vaccine_group + pre_wave_infection_group + 
                                          ethnicity + imd + multimorb_cat + strata(region)")), 
                        data = data_filtered)
      }
      
      # Pick out adjusted outputs for term of interest
      tidy = broom.helpers::tidy_plus_plus(cox_adj, exponentiate = TRUE) 
      tidy = subset(tidy, variable==paste0("factor(",group,")")) %>% 
        rename(group = label) %>%
        mutate(
          group = as.character(group),
          n_obs = plyr::round_any(n_obs, 5), # used to cross check IR calculations
          n_event = plyr::round_any(n_event, 5),
          exposure = plyr::round_any(exposure, 5)
        ) %>%
        select(group, n_obs, n_event, exposure, estimate, std.error, statistic, p.value, conf.low, conf.high)
      names(tidy)[2:ncol(tidy)] = paste0(names(tidy)[2:ncol(tidy)],"_full")
      
      # Merge with crude IRs
      ir_crude <- left_join(ir_crude, tidy, by = "group")
      
    }
    
    # Apply additional redactions
    redaction_columns = c("events", "time", "ir", "ir_lower_ci", "ir_upper_ci", model_cols)
    for (i in 1:nrow(ir_crude)) {
      if (as.numeric(ir_crude$events[i])>0 & as.numeric(ir_crude$events[i])<=redaction_threshold) { ir_crude[i,redaction_columns] = NA }
      if (as.numeric(ir_crude$n[i])>0 & as.numeric(ir_crude$n[i])<=redaction_threshold) { ir_crude[i,c("n", redaction_columns)] = NA }
    }
    
    # Secondary redactions
    if( subgroups_vctr[s]!="N" & (sum(ir_crude$events>redaction_threshold, na.rm=T) < 2) ) { 
      ir_crude[,redaction_columns] = NA 
    }
    if( subgroups_vctr[s]!="N" & (sum(ir_crude$n>redaction_threshold, na.rm=T) < 2) ) { 
      ir_crude[,c("n",redaction_columns)] = NA 
    }

    ir_crude$variable = subgroups_vctr[s]
    ir_crude$outcome = outcomes[o]
    if(s==1 & o==1) { ir_collated = ir_crude } else { ir_collated = rbind(ir_collated, ir_crude) }
  }
}

# Reorder columns
ir_collated = ir_collated %>% relocate(variable,outcome)


# Save output
output_dir <- here("output", "table_ir_hr")
fs::dir_create(output_dir)
write_csv(ir_collated, here::here("output", "table_ir_hr",  paste0("table_ir_hr_",wave,"_",subgroup,".csv")))

# Create simplified output
ir_simple = ir_collated %>%
  mutate(
    hr_min = round(estimate_min,2),
    hr_lower_min = round(conf.low_min,2),
    hr_upper_min = round(conf.high_min,2),
    hr_adj = round(estimate_adj,2),
    hr_lower_adj = round(conf.low_adj,2),
    hr_upper_adj = round(conf.high_adj,2),
    hr_full = round(estimate_full,2),
    hr_lower_full = round(conf.low_full,2),
    hr_upper_full = round(conf.high_full,2)
  ) %>%
  select(
    variable, outcome, group, n, events, time, 
    ir, ir_lower_ci, ir_upper_ci, 
    hr_min, hr_lower_min, hr_upper_min,
    hr_adj, hr_lower_adj, hr_upper_adj,
    hr_full, hr_lower_full, hr_upper_full
  ) %>%
  filter(variable != "region")

# Save output
write_csv(ir_simple, here::here("output", "table_ir_hr",  paste0("table_ir_hr_",wave,"_",subgroup,"_simple.csv")))

