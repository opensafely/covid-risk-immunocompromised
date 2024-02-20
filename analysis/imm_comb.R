# # # # # # # # # # # # # # # # # # # # #
# This script creates an upset plot for immunosuppression subgroups
# # # # # # # # # # # # # # # # # # # # #

# Import libraries
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
  wave <- "wave4"
} else {
  wave <- args[[1]]
}

# Import filtered data
d <- read_rds(here::here("output", "filtered", paste0("input_",wave,".rds")))

## Broad categories

# Create text coding for each group
d = d %>%
  mutate(
    any_transplant_alt = if_else(any_transplant == 1, "Tx", "0"),
    haem_cancer_alt = if_else(haem_cancer == 1, "HC", "0"),
    immunosuppression_diagnosis_alt = if_else(immunosuppression_diagnosis == 1, "IMD", "0"),
    immunosuppression_medication_alt = if_else(immunosuppression_medication == 1, "IMM", "0"),
    radio_chemo_alt = if_else(radio_chemo == 1, "RC", "0")
  )
    
# Combine text coding
d$immuno_combined = paste0(
  d$any_transplant_alt,"-",
  d$haem_cancer_alt,"-",
  d$immunosuppression_diagnosis_alt,"-",
  d$immunosuppression_medication_alt,"-",
  d$radio_chemo_alt
)

# Summarise set sizes
sets = data.frame("Group" = c("Tx", "HC", "IMD", "IMM", "RC"),
                  "Count" = c(
                    plyr::round_any(sum(d$any_transplant), 5),
                    plyr::round_any(sum(d$haem_cancer), 5),
                    plyr::round_any(sum(d$immunosuppression_diagnosis), 5),
                    plyr::round_any(sum(d$immunosuppression_medication), 5),
                    plyr::round_any(sum(d$radio_chemo), 5)
                  ),
                  "Type" = "Set"
)
# Collate combinations
collated = data.frame(table(d$immuno_combined)) %>% arrange(-Freq)
names(collated) = c("Group", "Count")

# Group counts of <100 as 'Other'
collated_other = data.frame("Group" = "Other",
                            "Count" = sum(collated$Count[collated$Count<100])) 
collated_final = rbind(collated[collated$Count>=100,], collated_other)  %>%
  mutate(Count = plyr::round_any(Count, 5),
         Type = "Combo")

# Collate sets and combinations
collated_final = rbind(sets, collated_final)

## Save as csv
output_dir <- here("output", "imm_comb")
fs::dir_create(output_dir)
write_csv(collated_final, here::here("output", "imm_comb",  paste0("imm_comb_",wave,"_broad.csv")))


## Narrow categories

# Create text coding for each group
d = d %>%
  mutate(
    any_transplant_alt = case_when(
      any_transplant_cat == "Bone marrow" ~ "Tx (BM)",
      any_transplant_cat == "Solid organ" ~ "Tx (SOT)",
      TRUE ~ "0"
    ),
    haem_cancer_alt = case_when(
      haem_cancer_cat == ">1 year" ~ "HC (>1y)",
      haem_cancer_cat == "<=1 year" ~ "HC (<=1y)",
      TRUE ~ "0"
    ),
    immunosuppression_diagnosis_alt = case_when(
      immunosuppression_diagnosis_cat == ">1 year" ~ "IMD (>1y)",
      immunosuppression_diagnosis_cat == "<=1 year" ~ "IMD (<=1y)",
      TRUE ~ "0"
    ),
    immunosuppression_medication_alt = case_when(
      immunosuppression_medication_cat == ">3 months" ~ "IMM (>3m)",
      immunosuppression_medication_cat == "<=3 months" ~ "IMM (<=3m)",
      TRUE ~ "0"
    ),
    radio_chemo_alt = case_when(
      radio_chemo_cat == ">6 months" ~ "RC (>6m)",
      radio_chemo_cat == "<=6 months" ~ "RC (<=6m)",
      TRUE ~ "0"
    )
  )

# Combine text coding
d$immuno_combined = paste0(
  d$any_transplant_alt,"-",
  d$haem_cancer_alt,"-",
  d$immunosuppression_diagnosis_alt,"-",
  d$immunosuppression_medication_alt,"-",
  d$radio_chemo_alt
)

# Summarise set sizes
sets = data.frame("Group" = c("Tx (BM)", "Tx (SOT)", 
                              "HC (>1y)", "HC (<=1y)",
                              "IMD (>1y)", "IMD (<=1y)",
                              "IMM (>3m)", "IMM (<=3m)",
                              "RC (>6m)", "RC (<=6m)"),
                  "Count" = c(
                    plyr::round_any(sum(d$any_transplant_cat_broad=="Bone marrow", na.rm=T), 5),
                    plyr::round_any(sum(d$any_transplant_cat_broad=="Solid organ", na.rm=T), 5),
                    plyr::round_any(sum(d$haem_cancer_cat==">1 year", na.rm=T), 5),
                    plyr::round_any(sum(d$haem_cancer_cat=="<=1 year", na.rm=T), 5),
                    plyr::round_any(sum(d$immunosuppression_diagnosis_cat==">1 year", na.rm=T), 5),
                    plyr::round_any(sum(d$immunosuppression_diagnosis_cat=="<=1 year", na.rm=T), 5),
                    plyr::round_any(sum(d$immunosuppression_medication_cat==">3 months", na.rm=T), 5),
                    plyr::round_any(sum(d$immunosuppression_medication_cat=="<=3 months", na.rm=T), 5),
                    plyr::round_any(sum(d$radio_chemo_cat==">6 months", na.rm=T), 5),
                    plyr::round_any(sum(d$radio_chemo_cat=="<=6 months", na.rm=T), 5)
                  ),
                  "Type" = "Set"
)

# Collate combinations
collated = data.frame(table(d$immuno_combined)) %>% arrange(-Freq)
names(collated) = c("Group", "Count")

# Group counts of <100 as 'Other'
collated_other = data.frame("Group" = "Other",
                            "Count" = sum(collated$Count[collated$Count<100])) 
collated_final = rbind(collated[collated$Count>=100,], collated_other)  %>%
  mutate(Count = plyr::round_any(Count, 5),
         Type = "Combo")

# Collate sets and combinations
collated_final = rbind(sets, collated_final)

## Save as csv
write_csv(collated_final, here::here("output", "imm_comb",  paste0("imm_comb_",wave,"_narrow.csv")))

