# Define era-specific exposures across waves

from cohortextractor import (
    patients,
    combine_codelists,
)

import codelists

era_exposure_variables = dict(

    # WT
    # Positive test
    wt_positive_test_date = patients.with_test_result_in_sgss(
        pathogen = "SARS-CoV-2",
        test_result = "positive",
        returning = "date",
        date_format = "YYYY-MM-DD",
        between=["2020-03-23","2020-09-06"],
        find_last_match_in_period=True,
        restrict_to_earliest_specimen_date=False,
        return_expectations = {
            "date": {"earliest": "2020-03-23", "latest": "2020-09-06"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
  
    # Case identification
    wt_primary_care_date = patients.with_these_clinical_events(
        combine_codelists(
            codelists.covid_primary_care_code,
            codelists.covid_primary_care_positive_test,
            codelists.covid_primary_care_sequalae,
        ),
        returning="date",
        date_format="YYYY-MM-DD",
        between=["2020-03-23","2020-09-06"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2020-03-23", "latest": "2020-09-06"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
      
    # Hospitalisation
    wt_hospitalisation_date = patients.admitted_to_hospital(
        with_these_diagnoses = codelists.covid_icd10,
        with_admission_method = ["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        returning = "date_admitted",
        date_format="YYYY-MM-DD",
        between=["2020-03-23","2020-09-06"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2020-03-23", "latest": "2020-09-06"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # A&E
    wt_emergency_date = patients.attended_emergency_care(
        with_these_diagnoses = codelists.covid_emergency,
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        between=["2020-03-23","2020-09-06"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2020-03-23", "latest": "2020-09-06"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # ALPHA
    # Positive test
    alpha_positive_test_date = patients.with_test_result_in_sgss(
        pathogen = "SARS-CoV-2",
        test_result = "positive",
        returning = "date",
        date_format = "YYYY-MM-DD",
        between=["2020-09-07","2021-05-27"],
        find_last_match_in_period=True,
        restrict_to_earliest_specimen_date=False,
        return_expectations = {
            "date": {"earliest": "2020-09-07", "latest": "2021-05-27"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
      
    # Hospitalisation
    alpha_hospitalisation_date = patients.admitted_to_hospital(
        with_these_diagnoses = codelists.covid_icd10,
        with_admission_method = ["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        returning = "date_admitted",
        date_format="YYYY-MM-DD",
        between=["2020-09-07","2021-05-27"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2020-09-07", "latest": "2021-05-27"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # A&E
    alpha_emergency_date = patients.attended_emergency_care(
        with_these_diagnoses = codelists.covid_emergency,
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        between=["2020-09-07","2021-05-27"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2020-09-07", "latest": "2021-05-27"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # DELTA
    # Positive test
    delta_positive_test_date = patients.with_test_result_in_sgss(
        pathogen = "SARS-CoV-2",
        test_result = "positive",
        returning = "date",
        date_format = "YYYY-MM-DD",
        between=["2021-05-28","2021-12-14"],
        find_last_match_in_period=True,
        restrict_to_earliest_specimen_date=False,
        return_expectations = {
            "date": {"earliest": "2021-05-28", "latest": "2021-12-14"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
      
    # Hospitalisation
    delta_hospitalisation_date = patients.admitted_to_hospital(
        with_these_diagnoses = codelists.covid_icd10,
        with_admission_method = ["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],
        returning = "date_admitted",
        date_format="YYYY-MM-DD",
        between=["2021-05-28","2021-12-14"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2021-05-28", "latest": "2021-12-14"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # A&E
    delta_emergency_date = patients.attended_emergency_care(
        with_these_diagnoses = codelists.covid_emergency,
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        between=["2021-05-28","2021-12-14"],
        find_last_match_in_period=True,
        return_expectations = {
            "date": {"earliest": "2021-05-28", "latest": "2021-12-14"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
    
    # OMICRON
    # FIRST positive test (start of follow-up for secondary objective)
    omicron_positive_test_date = patients.with_test_result_in_sgss(
        pathogen = "SARS-CoV-2",
        test_result = "positive",
        returning = "date",
        date_format = "YYYY-MM-DD",
        between=["2021-12-15","2022-04-29"],
        find_first_match_in_period=True,
        restrict_to_earliest_specimen_date=False,
        return_expectations = {
            "date": {"earliest": "2021-12-15", "latest": "2022-04-29"}, # need both earliest/latest to obtain expected incidence
            "rate": "uniform",
            "incidence": 0.02,
            },
    ),
   
)
