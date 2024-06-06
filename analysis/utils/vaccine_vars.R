## ###########################################################

##  This script:
## - Contains a function that is calculates the number of doses at the start of each era
## - Contains a function that calculates the last dose before each era
## - Contains a function that calculates the first dose after each era

## ###########################################################

## Function 'add_n_doses()' to add the number of doses received before delta/omicron eras
## Arguments:
## data: extracted data
## Outputs:
## n_doses_delta - number of doses pre delta era (0, 1, 2, 3+)
## n_doses_omicron - number of doses pre omicron era  (0, 1, 2, 3+)
add_n_doses <- function(data){
  data <- 
    data %>%
    mutate(
      # dose counts at start of delta era
      n_doses_delta = fct_case_when(
        covid_vax_date_2<=delta_start_date ~ "2",
        covid_vax_date_1<=delta_start_date ~ "1",
        TRUE ~ "0"
      ),
      # reverse order
      n_doses_delta = fct_case_when(
        n_doses_delta == "0" ~ "0",
        n_doses_delta == "1" ~ "1",
        n_doses_delta == "2" ~ "2"
      ),
      
      # dose counts at start of omicron era
      n_doses_omicron = fct_case_when(
        covid_vax_date_3<=omicron_start_date ~ "3+",
        covid_vax_date_2<=omicron_start_date ~ "2",
        covid_vax_date_1<=omicron_start_date ~ "1",
        TRUE ~ "0"
      ),
      # reverse order
      n_doses_omicron = fct_case_when(
        n_doses_omicron == "0" ~ "0",
        n_doses_omicron == "1" ~ "1",
        n_doses_omicron == "2" ~ "2",
        n_doses_omicron == "3+" ~ "3+"
      ),
      # dose counts at start of omicron era
      n_doses_jn1 = fct_case_when(
        covid_vax_date_8<=jn1_start_date ~ "8+",
        covid_vax_date_7<=jn1_start_date ~ "7",
        covid_vax_date_6<=jn1_start_date ~ "6",
        covid_vax_date_5<=jn1_start_date ~ "5",
        covid_vax_date_4<=jn1_start_date ~ "4",
        covid_vax_date_3<=jn1_start_date ~ "3",
        covid_vax_date_2<=jn1_start_date ~ "2",
        covid_vax_date_1<=jn1_start_date ~ "1",
        TRUE ~ "0"
      ),
      # reverse order
      n_doses_jn1 = fct_case_when(
        n_doses_jn1 %in% c("0", "1", "2") ~ "0-2",
        n_doses_jn1 %in% c("3", "4") ~ "3-4",
        n_doses_jn1 %in% c("5", "6") ~ "5-6",
        n_doses_jn1 == "7" ~ "7",
        n_doses_jn1 == "8+" ~ "8+"
      ),
    )
}

## Function 'last_dose_pre_era()' to define time window to most recent dose
## Arguments:
## data: extracted data
## era: "delta" or "omicron"
## Outputs:
## pre_[era]_last_vax_date - date of last dose before start of [era]
## pre_[era]_vax_diff - difference in days between last dose and start of [era]
## pre_[era]_vaccine_group - category for differences in days 
last_dose_pre_era <- function(data, era=c("delta", "omicron", "jn1")){
  
  if (era=="delta") {
    data <- data %>% mutate(era_start_date = delta_start_date)
  } else  if (era=="omicron") {
    data <- data %>% mutate(era_start_date = omicron_start_date)
  } else {
    data <- data %>% mutate(era_start_date = jn1_start_date)
  }
  
  data <- data %>%
    mutate(
      # Create modified vaccination variables where records after era start date set to NA
      covid_vax_date_1_mod = if_else(covid_vax_date_1<=era_start_date, covid_vax_date_1, ymd(NA)),
      covid_vax_date_2_mod = if_else(covid_vax_date_2<=era_start_date, covid_vax_date_2, ymd(NA)),
      covid_vax_date_3_mod = if_else(covid_vax_date_3<=era_start_date, covid_vax_date_3, ymd(NA)),
      covid_vax_date_4_mod = if_else(covid_vax_date_4<=era_start_date, covid_vax_date_4, ymd(NA)),
      covid_vax_date_5_mod = if_else(covid_vax_date_5<=era_start_date, covid_vax_date_5, ymd(NA)),
      covid_vax_date_6_mod = if_else(covid_vax_date_6<=era_start_date, covid_vax_date_6, ymd(NA)),
      covid_vax_date_7_mod = if_else(covid_vax_date_7<=era_start_date, covid_vax_date_7, ymd(NA)),
      covid_vax_date_8_mod = if_else(covid_vax_date_8<=era_start_date, covid_vax_date_8, ymd(NA)),
      covid_vax_date_9_mod = if_else(covid_vax_date_9<=era_start_date, covid_vax_date_9, ymd(NA)),
      covid_vax_date_10_mod = if_else(covid_vax_date_10<=era_start_date, covid_vax_date_10, ymd(NA)),
      
      # Pick last dose date pre era
      pre_era_last_vax_date = pmax(covid_vax_date_1_mod, covid_vax_date_2_mod, covid_vax_date_3_mod, 
                                covid_vax_date_4_mod, covid_vax_date_5_mod, covid_vax_date_6_mod, 
                                covid_vax_date_7_mod, covid_vax_date_8_mod,
                                covid_vax_date_9_mod, covid_vax_date_10_mod, na.rm=TRUE),
      
      # Difference in days between last dose and start of era
      pre_era_vax_diff = as.numeric(era_start_date - pre_era_last_vax_date),
      
      # Pre-era windows
      pre_era_vaccine_group = fct_case_when(
        is.na(pre_era_last_vax_date) ~ "Unvaccinated",
        pre_era_vax_diff>(26*7) ~ "27+ weeks",
        pre_era_vax_diff>(12*7) & pre_era_vax_diff<=(26*7) ~ "13-26 weeks",
        pre_era_vax_diff>(2*7) & pre_era_vax_diff<=(12*7) ~ "3-12 weeks",
        pre_era_vax_diff>=0 & pre_era_vax_diff<=(2*7) ~ "0-2 weeks",
        TRUE ~ NA_character_
      )
    ) 
  
  if (era=="delta") {
    data <- data %>% mutate(
      pre_delta_last_vax_date = pre_era_last_vax_date,
      pre_delta_vax_diff = pre_era_vax_diff,
      pre_delta_vaccine_group = pre_era_vaccine_group,
    ) 
  } else if (era=="omicron")  {
    data <- data %>% mutate(
      pre_omicron_last_vax_date = pre_era_last_vax_date,
      pre_omicron_vax_diff = pre_era_vax_diff,
      pre_omicron_vaccine_group = pre_era_vaccine_group,
    )
  } else {
    data <- data %>% mutate(
      pre_jn1_last_vax_date = pre_era_last_vax_date,
      pre_jn1_vax_diff = pre_era_vax_diff,
      pre_jn1_vaccine_group = pre_era_vaccine_group,
    )
  }
    # Remove temporary variables
    data <- data %>%
      select(-c(covid_vax_date_1_mod, covid_vax_date_2_mod, covid_vax_date_3_mod, 
                covid_vax_date_4_mod, covid_vax_date_5_mod, covid_vax_date_6_mod,
                covid_vax_date_7_mod, covid_vax_date_8_mod, covid_vax_date_9_mod, covid_vax_date_10_mod,
                era_start_date, pre_era_last_vax_date, pre_era_vax_diff, pre_era_vaccine_group))
}

## Function 'first_dose_post_era()' to define time window to most recent dose
## Arguments:
## data: extracted data
## era: "alpha", "delta" or "omicron"
## Outputs:
## post_[era]_first_vax_date - date of first dose after start of [era]
first_dose_post_era <- function(data, era=c("alpha", "delta", "omicron", "jn1")){
  
  if (era=="alpha") {
    data <- data %>% mutate(era_start_date = alpha_start_date)
  } else if (era=="delta") {
    data <- data %>% mutate(era_start_date = delta_start_date)
  } else if (era=="omicron") {
    data <- data %>% mutate(era_start_date = omicron_start_date)
  } else {
    data <- data %>% mutate(era_start_date = jn1_start_date)
  }
  
  data <- 
    data %>%
    mutate(
      # Create modified vaccination variables where records after era start date set to NA
      covid_vax_date_1_mod = if_else(covid_vax_date_1>era_start_date, covid_vax_date_1, ymd(NA)),
      covid_vax_date_2_mod = if_else(covid_vax_date_2>era_start_date, covid_vax_date_2, ymd(NA)),
      covid_vax_date_3_mod = if_else(covid_vax_date_3>era_start_date, covid_vax_date_3, ymd(NA)),
      covid_vax_date_4_mod = if_else(covid_vax_date_4>era_start_date, covid_vax_date_4, ymd(NA)),
      covid_vax_date_5_mod = if_else(covid_vax_date_5>era_start_date, covid_vax_date_5, ymd(NA)),
      covid_vax_date_6_mod = if_else(covid_vax_date_6>era_start_date, covid_vax_date_6, ymd(NA)),
      covid_vax_date_7_mod = if_else(covid_vax_date_7>era_start_date, covid_vax_date_7, ymd(NA)),
      covid_vax_date_8_mod = if_else(covid_vax_date_8>era_start_date, covid_vax_date_8, ymd(NA)),
      covid_vax_date_9_mod = if_else(covid_vax_date_9>era_start_date, covid_vax_date_9, ymd(NA)),
      covid_vax_date_10_mod = if_else(covid_vax_date_10>era_start_date, covid_vax_date_10, ymd(NA)),
      
      # Pick first dose date post era
      post_era_first_vax_date = pmin(covid_vax_date_1_mod, covid_vax_date_2_mod, covid_vax_date_3_mod, 
                                   covid_vax_date_4_mod, covid_vax_date_5_mod, covid_vax_date_6_mod,
                                   covid_vax_date_7_mod, covid_vax_date_8_mod,
                                   covid_vax_date_9_mod, covid_vax_date_10_mod, na.rm=TRUE),
      
    ) 
  
  if (era=="alpha") {
    data <- data %>% mutate(
      post_alpha_first_vax_date = post_era_first_vax_date,
    ) 
  } else if (era=="delta") {
    data <- data %>% mutate(
      post_delta_first_vax_date = post_era_first_vax_date,
    ) 
  } else if (era=="omicron") {
    data <- data %>% mutate(
      post_omicron_first_vax_date = post_era_first_vax_date,
    ) 
  } else {
    data <- data %>% mutate(
      post_jn1_first_vax_date = post_era_first_vax_date,
    ) 
  }
  
  # Remove temporary variables
  data <- data %>%
    select(-c(covid_vax_date_1_mod, covid_vax_date_2_mod, covid_vax_date_3_mod, 
              covid_vax_date_4_mod, covid_vax_date_5_mod, covid_vax_date_6_mod,
              covid_vax_date_7_mod, covid_vax_date_8_mod, covid_vax_date_9_mod, covid_vax_date_10_mod, 
              era_start_date, post_era_first_vax_date))
}
