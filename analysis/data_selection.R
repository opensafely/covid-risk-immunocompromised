
# # # # # # # # # # # # # # # # # # # # #
# This script:
# imports processed data
# filters out people who are excluded from the main analysis
# outputs inclusion/exclusions flowchart data
# # # # # # # # # # # # # # # # # # # # #

# Import libraries
library(tidyverse)
library(here)
library(glue)

# Select wave based on input arguments
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  wave <- "wave4"
} else {
  wave <- args[[1]]
}

# Import processed data
data_processed <- read_rds(here::here("output", "processed", paste0("input_",wave,".rds")))

# Function fct_case_when needed inside process_data
source(here("analysis", "utils", "fct_case_when.R"))                           

# Define selection criteria
data_criteria <- data_processed %>%
  transmute(
    patient_id,
    
    # Made it into into study population with valid age
    study_definition = TRUE,
    has_follow_up = has_follow_up==1,
    has_age = !is.na(age) & age >=18 & age<=110,
    has_sex = !is.na(sex),
    
    # At least 1 ICP flag
    is_ICP = organ_transplant==1 | bone_marrow_transplant==1 | haem_cancer==1 |
      immunosuppression_diagnosis==1 | immunosuppression_medication==1 | radio_chemo==1,
    
    # Demography
    has_imd = !is.na(imd),
    has_ethnicity = !is.na(ethnicity),
    has_region = !is.na(region),
    
    # Postvax events
    severe_date_check = is.na(covid_severe_date) | covid_severe_date>omicron_start_date,
    death_date_check = is.na(covid_death_date) | covid_death_date>omicron_start_date,
    noncoviddeath_date_check = is.na(died_any_date) | died_any_date>omicron_start_date,
    
    # Define primary outcome study population
    include = (
      has_follow_up & has_age & has_sex &
      is_ICP &
      has_imd & has_ethnicity & has_region &
      severe_date_check & death_date_check & noncoviddeath_date_check
     )
  )

# Create cohort data including patients fulfilling selection criteria
data_filtered <- data_criteria %>%
  filter(include) %>%
  select(patient_id) %>%
  left_join(data_processed, by="patient_id")

# Save data
output_dir <- here("output", "filtered")
fs::dir_create(output_dir)
write_rds(data_filtered, here::here("output", "filtered", paste0("input_",wave,".rds")), compress="gz")
#write_csv(data_filtered, here::here("output", "filtered", paste0("input_",wave,".csv")))

# Create flow chart
data_flowchart <- data_criteria %>%
  transmute(
    c0 = (study_definition & has_follow_up & has_age & has_sex),
    c1 = c0 & is_ICP,
    c2 = c1 & (has_imd & has_ethnicity & has_region),
    c3 = c2 & (severe_date_check & death_date_check & noncoviddeath_date_check),
  ) %>%
  summarise(
    across(.fns=sum)
  ) %>%
  pivot_longer(
    cols=everything(),
    names_to="criteria",
    values_to="n"
  ) %>%
  mutate(
    n_exclude = lag(n) - n,
    pct_exclude = n_exclude/lag(n),
    pct_all = n / first(n),
    pct_step = n / lag(n),
    crit = str_extract(criteria, "^c\\d+"),
    criteria = fct_case_when(
      crit == "c0" ~ "Males and females aged >=18 years on index date with at least 3 months of continuous registration at a single GP",
      crit == "c1" ~ "Meets at least ICP definition", 
      crit == "c2" ~ "No missing demographic information (region, index of multiple deprivation, or ethnicity)",
      crit == "c3" ~ "No outcome or censoring events recorded before start of follow-up",
      TRUE ~ NA_character_
    )
  )

# Save flowchart
output_dir <- here("output", "flowchart")
fs::dir_create(output_dir)
write_csv(data_flowchart, here::here("output", "flowchart", paste0("flowchart_",wave,".csv")))
