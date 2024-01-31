######################################

# This script provides the formal specification of the study data that will
# be extracted from the OpenSAFELY database.
# This data extract is the data extract for immunocompromised persons relating to one of the UK pandemic waves
# See file name for wave number
# See config.json for start and end dates of the wave)

######################################

# IMPORT STATEMENTS ----
# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
    combine_codelists
)

# Import standard variable sets
from dict_demographic_vars import demographic_variables

from dict_comorbidity_vars import comorbidity_variables

from dict_era_exposure_vars import era_exposure_variables

import codelists

# Import config variables (start_date and end_date of wave)
# Import json module
import json
with open('analysis/config.json', 'r') as f:
    config = json.load(f)

# Set wave
wave = config["wave4"]
start_date = wave["start_date"]
end_date = wave["end_date"]

# DEFINE STUDY POPULATION ----
# Define study population and variables
study = StudyDefinition(
    
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": end_date},
        "rate": "uniform",
        "incidence": 0.95,
    },
    
    # Set index date to start date
    index_date=start_date,
    # Define the study population
    # IN AND EXCLUSION CRITERIA
    # (= > 1 year follow up, aged > 18 and no missings in age and sex)
    # missings in age are the ones > 110
    # missings in sex can be sex = U or sex = I (so filter on M and F)
    population=patients.satisfying(
        """
        NOT died
        AND
        (age >=18 AND age <= 110)
        AND
        (sex = "M" OR sex = "F")
        AND
        (organ_transplant OR bone_marrow_transplant OR haem_cancer OR immunosuppression_diagnosis OR immunosuppression_medication OR radio_chemo)
        AND
        index_of_multiple_deprivation != -1
        """,
        
        died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.01},
        ),
    ),
    
    
    # DEMOGRAPHICS
    **demographic_variables,
    
    # IMMUNOSUPPRESSION
    # Solid organ transplant
    organ_transplant=patients.with_these_clinical_events(
        combine_codelists(
            codelists.other_organ_transplant_codes,
            codelists.kidney_transplant_codes
         ),  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: organ_transplant_date
        date_format="YYYY-MM-DD",
    ),
    
    # Bone marrow transplant
    bone_marrow_transplant=patients.with_these_clinical_events(
        codelists.bone_marrow_transplant_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: bone_marrow_transplant_date
        date_format="YYYY-MM-DD",
    ),
  
    # Haematological malignancy (binary and date of last match)
    haem_cancer=patients.with_these_clinical_events(
        codelists.haem_cancer_codes,  # imported from codelists.py
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: haem_cancer_date
        date_format="YYYY-MM-DD",
    ),
  
    # Immunosuppression diagnosis
    immunosuppression_diagnosis = patients.with_these_clinical_events(
        codelists.immunosupression_diagnosis_codes,
        returning="binary_flag",
        on_or_before="index_date",
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: immunosuppression_diagnosis_date
        date_format="YYYY-MM-DD",
    ),
    
    # Immunosuppression medication
    immunosuppression_medication = patients.with_these_medications(
        codelists.immunosuppression_medication_codes,
        returning="binary_flag",
        #between=["index_date - 182 days", "index_date"], # use for waves 1 and 2
        between=["2020-07-01","index_date"], # use for waves 3 and 4
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: immunosuppression_medication_date
        date_format="YYYY-MM-DD",
    ),
    
    # Immunosuppression admin code
    immunosuppression_admin = patients.with_these_medications(
        codelists.immunosuppression_admin_codes,
        returning="binary_flag",
        #between=["index_date - 182 days", "index_date"], # use for waves 1 and 2
        between=["2020-07-01","index_date"], # use for waves 3 and 4
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: immunosuppression_admin_date
        date_format="YYYY-MM-DD",
    ),
    
    # Radiotherapy/chemotherapy
    radio_chemo = patients.with_these_medications(
        codelists.radio_chemo_codes,
        returning="binary_flag",
        #between=["index_date - 182 days", "index_date"], # use for waves 1 and 2
        between=["2020-07-01","index_date"], # use for waves 3 and 4
        find_last_match_in_period=True,
        include_date_of_match=True, # variable: radio_chemo_date
        date_format="YYYY-MM-DD",
    ),


    # COMORBIDITIES
    **comorbidity_variables,
    
    
    # ERA EXPOSURES
    **era_exposure_variables,


    # OUTCOMES (not in dict because end_date is used)
    # Covid-related admission
    covid_hospitalisation_date = patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=codelists.covid_icd10,
        with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        between=["index_date",end_date],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.2,
        },
    ),
    
    # Covid-related A&E
    covid_emergency_date = patients.attended_emergency_care(
        returning="date_arrived",
        with_these_diagnoses = codelists.covid_emergency,
        between=["index_date",end_date],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.2,
        },
    ),
    
    # Covid-related death
    covid_death_date=patients.with_these_codes_on_death_certificate(
        codelists.covid_icd10,  # imported from codelists.py
        returning="date_of_death",
        between=["index_date", end_date],
        match_only_underlying_cause=False,  # boolean for indicating if filters
        # results to only specified cause of death
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.05,
        },
    ),
    
    # Death from any cause (to be used for censoring)
    died_any_date=patients.died_from_any_cause(
        between=["index_date", end_date],
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.01,
        },
    ),
    
    # De-registration (to be used for censoring)
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        between=["index_date",end_date],
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date", "latest": end_date},
            "incidence": 0.01,
        },
    ),
      
 
    # VACCINATION HISTORY (not in dict because end_date is used)
    # Date of first COVID vaccination - source nhs-covid-vaccination-coverage
    covid_vax_date_1=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["2020-12-01", end_date],  # any dose recorded after 01/12/2020
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.8,
        },
    ),
    
    # Date of second COVID vaccination - source nhs-covid-vaccination-coverage
    covid_vax_date_2=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_1 + 14 days", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.6,
        },
    ),
    
    # Date of third COVID vaccination (primary or booster) -
    # modified from nhs-covid-vaccination-coverage
    # 01 Sep 2021: 3rd dose (primary) at interval of >=8w recommended for
    # immunosuppressed
    # 14 Sep 2021: 3rd dose (booster) reommended for JCVI groups 1-9 at >=6m
    # 15 Nov 2021: 3rd dose (booster) recommended for 40–49y at >=6m
    # 29 Nov 2021: 3rd dose (booster) recommended for 18–39y at >=3m
    covid_vax_date_3=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_2 + 14 days", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.5,
        },
    ),
    
    # Date of fourth COVID vaccination (booster) -
    covid_vax_date_4=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_3 + 14 days", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.5,
        },
    ),
    
    # Date of fifth COVID vaccination (booster) -
    covid_vax_date_5=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_4 + 14 days", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.5,
        },
    ),
    
    # Date of sixth COVID vaccination (booster) -
    covid_vax_date_6=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        between=["covid_vax_date_5 + 14 days", end_date],  # from day after previous dose
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-12-01", "latest": end_date},
            "incidence": 0.5,
        },
    ),
)
