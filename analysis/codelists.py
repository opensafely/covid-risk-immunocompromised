######################################

# Some covariates used in the study are created from codelists of clinical
# conditions or numerical values available on a patient's records.
# This script fetches all of the codelists identified in codelists.txt from
# OpenCodelists.

######################################

# --- IMPORT STATEMENTS ---
# Import code building blocks from cohort extractor package
from cohortextractor import (
    codelist,
    codelist_from_csv,
)

# --- CODELISTS ---

# STUDY DEFINITION

# Organ transplant (excluding kidney transplants)
other_organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-other-organ-transplant.csv",
    system="ctv3",
    column="CTV3ID",
)

# Kidney transplant
kidney_transplant_codes = codelist_from_csv(
  "codelists/opensafely-kidney-transplant.csv",
  system="ctv3",
  column="CTV3ID",
)

# Bone marrow transplant
bone_marrow_transplant_codes = codelist_from_csv(
    "codelists/opensafely-bone-marrow-transplant.csv",
    system="ctv3",
    column="CTV3ID",
)

# Haematologic cancer
haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv",
    system="ctv3",
    column="CTV3ID",
)

# Immunosuppressive diagnosis
immunosupression_diagnosis_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immdx_cov.csv",
    system="snomed",
    column="code",
)

# Immunosuppressive medication
immunosuppression_medication_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immrx.csv",
    system="snomed",
    column="code",
)

# Radiotherapy/chemotherapy
radio_chemo_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-dxt_chemo_cod.csv",
    system="snomed",
    column="code",
)

# Covid-related outcomes
# U071: COVID-19, virus identified
# U072: COVID-19, virus not identified
covid_icd10 = codelist(["U071", "U072"], system="icd10")
covid_emergency = codelist(["1240751000000100"], system="snomed")


# DEMOGRAPHIC VARIABLES DICTIONARY

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

# Care home
carehome_primis_codes = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-longres.csv",
  system = "snomed",
  column = "code",
)

# Smoking
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)


# COMORBIDITY VARIABLES DICTIONARY

# Diagnosed hypertension
hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv",
    system="ctv3",
    column="CTV3ID",
)

# Respiratory disease ex asthma
chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Asthma
asthma_codes = codelist_from_csv(
    "codelists/opensafely-asthma-diagnosis.csv",
    system="ctv3",
    column="CTV3ID",
)

# Blood pressure
systolic_blood_pressure_codes = codelist(
    ["2469."],
    system="ctv3",)
diastolic_blood_pressure_codes = codelist(
    ["246A."],
    system="ctv3")

# Presence of a prescription for a course of prednisolone (likely to be related
# to poor asthma control)
pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)

# Chronic cardiac disease
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Diabetes
diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv",
    system="ctv3",
    column="CTV3ID",
)

# Measures of hba1c
# 'new' codes: hba1c in mmol/mol
hba1c_new_codes = codelist_from_csv(
    "codelists/opensafely-glycated-haemoglobin-hba1c-tests-ifcc.csv",
    system="ctv3",
    column="code",
)
# 'old' codes: hba1c in percentage, should not be used in clinical practice but
#  best to use both
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")

# Cancer
lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv",
    system="ctv3",
    column="CTV3ID",
)
other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)

# Dialysis
dialysis_codes = codelist_from_csv(
  "codelists/opensafely-dialysis.csv",
  system="ctv3",
  column="CTV3ID",
)

# Creatinine codes
creatinine_codes = codelist(["XE2q5"], system="ctv3")

# Chronic liver disease
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

# Stroke
stroke = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv",
    system="ctv3",
    column="CTV3ID",
)

# Dementia
dementia = codelist_from_csv(
    "codelists/opensafely-dementia.csv",
    system="ctv3",
    column="CTV3ID",
)

# Other neurolgoical disease
other_neuro = codelist_from_csv(
    "codelists/opensafely-other-neurological-conditions.csv",
    system="ctv3",
    column="CTV3ID",
)

# Asplenia (splenectomy or a spleen dysfunction, including sickle cell disease)
sickle_cell_codes = codelist_from_csv(
    "codelists/opensafely-sickle-cell-disease.csv",
    system="ctv3",
    column="CTV3ID",
)
spleen_codes = codelist_from_csv(
    "codelists/opensafely-asplenia.csv",
    system="ctv3",
    column="CTV3ID",
)

# Rheumatoid/Lupus/Psoriasis diagnosis
ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/opensafely-ra-sle-psoriasis.csv",
    system="ctv3",
    column="CTV3ID",
)

# Learning disabilities
learning_disability_codes = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-ld_cod.csv",
  system="snomed",
  column="code",
)

# Severe mental illness
sev_mental_ill_codes = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-sev_mental.csv",
  system="snomed",
  column="code",
)


# ERA EXPOSURE DICTIONARY

# Case identification
covid_primary_care_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system = "ctv3",
    column = "CTV3ID",
)
covid_primary_care_positive_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system = "ctv3",
    column = "CTV3ID",
)
covid_primary_care_sequalae = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system = "ctv3",
    column = "CTV3ID",
)
