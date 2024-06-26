######################################

# This script 
# - produces a table summarising selected clinical and demographic groups in study cohort, stratified by primary vaccine product
# - saves table as html

######################################

## Import libraries
library(tidyverse)
library(here)
library(glue)
library(dplyr)
library(gt)
library(gtsummary)
library(reshape2)

# Select wave and subgroup based on input arguments
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  wave <- "wavejn1"
  subgroup <- "all"
} else {
  wave <- args[[1]]
  subgroup <- args[[2]]
}

# Import function to rename subgroups
source(here("analysis", "utils", "rename_subgroups.R"))

# Import filtered data
data_filtered <- read_rds(here::here("output", "filtered", paste0("input_",wave,".rds")))

## Set rounding and redaction thresholds
rounding_threshold = 5
redaction_threshold = 10


## Select subset
if (subgroup=="all") {
  data_filtered = data_filtered
} else if (subgroup!="all") {
  data_filtered = subset(data_filtered, imm_subgroup==subgroup)
} else {
  stop ("Arguments not specified correctly.")
}


## Merge 0/1 multimorb_cat in Tx subgroup due to colinearity with kidney Tx
source(here("analysis", "utils", "fct_case_when.R"))
if (subgroup=="Tx") {
  data_filtered = data_filtered %>% 
    mutate(
      multimorb_cat = fct_case_when(
        multimorb_cat=="0" | multimorb_cat=="1" ~ "0/1",
        multimorb_cat=="2" ~ "2",
        multimorb_cat=="3" ~ "3",
        multimorb_cat=="4+" ~ "4+"
      )
    )
}

# Format data
data_filtered <- data_filtered %>%
  mutate(
    N = 1,
  ) 

## Baseline variables
counts <- data_filtered %>%
  select(N,
         
         # Demographics
         agegroup,
         agegroup_broad,
         sex,
         ethnicity,
         ethnicity_broad,
         region,
         imd,
         care_home,
         smoking_status_comb,

         # Immunosuppression
         imm_subgroup,
         any_transplant_type,
         any_transplant_cat,
         any_bone_marrow_type,
         any_bone_marrow_cat,
         radio_chemo_cat,
         immunosuppression_medication_cat,
         immunosuppression_diagnosis_cat,
         
         # Immunosuppression (binary)
         any_transplant,
         any_bone_marrow,
         radio_chemo,
         immunosuppression_medication,
         immunosuppression_diagnosis,
         
         # Vaccination
         n_doses_wave,
         pre_wave_vaccine_group,
         
         # Prior infection group
         pre_wave_infection_group,
         
         # Prior infection/vaccination
         pre_wave_vax_infection_comb,
         pre_wave_vax_infection_comb_narrow,
         
         # At risk morbidity count
         multimorb_cat,
         
         ## Risk group (clinical)
         bmi,
         asthma,
         diabetes_controlled,
         ckd_rrt,
         bp_ht,
         chronic_respiratory_disease,
         chronic_cardiac_disease,
         cancer,
         chronic_liver_disease,
         stroke,
         dementia,
         other_neuro,
         asplenia,
         ra_sle_psoriasis,
         learning_disability,
         sev_mental_ill
         )

# Retain detailed immunosuppression variable for all data or specific subset, otherwise retain binary variable
if (subgroup=="all") {
  counts = counts %>% select(-c(any_transplant, any_bone_marrow, radio_chemo, immunosuppression_medication, immunosuppression_diagnosis))
}
if (subgroup=="Tx") {
  counts = counts %>% select(-c(imm_subgroup, any_bone_marrow_type, any_bone_marrow_cat, radio_chemo_cat, immunosuppression_medication_cat, immunosuppression_diagnosis_cat, 
                                any_transplant, ckd_rrt))
}
if (subgroup=="HC") {
  counts = counts %>% select(-c(imm_subgroup, any_transplant_type, any_transplant_cat, radio_chemo_cat, immunosuppression_medication_cat, immunosuppression_diagnosis_cat, 
                                any_bone_marrow, immunosuppression_diagnosis))
}
if (subgroup=="RC") {
  counts = counts %>% select(-c(imm_subgroup, any_transplant_type, any_transplant_cat, any_bone_marrow_type, any_bone_marrow_cat, immunosuppression_medication_cat, immunosuppression_diagnosis_cat, 
                                radio_chemo))
} 
if (subgroup=="IMM") {
  counts = counts %>% select(-c(imm_subgroup, any_transplant_type, any_transplant_cat, any_bone_marrow_type, any_bone_marrow_cat, radio_chemo_cat, immunosuppression_diagnosis_cat, 
                                immunosuppression_medication))
}
if (subgroup=="IMD") {
  counts = counts %>% select(-c(imm_subgroup, any_transplant_type, any_transplant_cat, any_bone_marrow_type, any_bone_marrow_cat, radio_chemo_cat, immunosuppression_medication_cat, 
                                immunosuppression_diagnosis))
}


## Create table 1
counts_summary = counts %>% tbl_summary()
counts_summary$inputs$data <- NULL
table1 <- counts_summary$table_body %>%
  select(group = variable, variable = label, count = stat_0) %>%
  separate(count, c("count","perc"), sep = "([(])") %>%
  mutate(count = gsub(" ", "", count)) %>%
  mutate(count = as.numeric(gsub(",", "", count))) %>%
  filter(!(is.na(count))) %>%
  select(-perc)
table1$percent = round(table1$count/nrow(data_filtered)*100,1)
colnames(table1) = c("subgroup", "level", "count", "percent")

# Relabel variables for plotting
table1 <- table1 %>% rename_subgroups()

## Calculate rounded total
rounded_n = plyr::round_any(nrow(data_filtered), rounding_threshold)

## Round individual values to rounding threshold
table1_redacted <- table1 %>%
  mutate(count = plyr::round_any(count, rounding_threshold))
table1_redacted$percent = round(table1_redacted$count/rounded_n*100,1)
table1_redacted$non_count = rounded_n - table1_redacted$count

## Redact any rows with rounded cell counts or non-counts <= redaction threshold 
table1_redacted$summary = paste0(prettyNum(table1_redacted$count, big.mark=",")," (",format(table1_redacted$percent,nsmall=1),"%)")
table1_redacted$summary = gsub(" ", "", table1_redacted$summary, fixed = TRUE) # Remove spaces generated by decimal formatting
table1_redacted$summary = gsub("(", " (", table1_redacted$summary, fixed = TRUE) # Add first space before (
table1_redacted$summary[table1_redacted$count<=redaction_threshold | table1_redacted$non_count<=redaction_threshold] = "[Redacted]"
table1_redacted$summary[table1_redacted$subgroup=="N"] = prettyNum(table1_redacted$count[table1_redacted$subgroup=="N"], big.mark=",")
table1_redacted$count[table1_redacted$summary=="[Redacted]"] = "[Redacted]"
table1_redacted$percent[table1_redacted$summary=="[Redacted]"] = "[Redacted]"
table1_redacted <- table1_redacted %>% select(-non_count)

## Save as html/rds
output_dir <- here("output", "table_1")
fs::dir_create(output_dir)
gt::gtsave(gt(table1_redacted), here::here("output","table_1", paste0("table_1_",wave,"_",subgroup,".html")))
write_csv(table1_redacted, here::here("output", "table_1",  paste0("table_1_",wave,"_",subgroup,".csv")))
write_rds(table1_redacted, here::here("output", "table_1", paste0("table_1_",wave,"_",subgroup,".rds")), compress = "gz")
