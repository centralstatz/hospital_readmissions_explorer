# Data Source

The datasets in this application come from the CMS Provider Data Catalog, which is a repository of data from the Center of Medicare and Medicaid Services (CMS).

Specifically, the data pertains to the Hospital Readmissions Reduction Program (HRRP). Each year, CMS penalizes hospitals across the USA up to 3% of their Medicare reimbursement for having too many readmissions.

A readmission occurs when a patient is readmitted to a hospital within 30 days after being previously discharged (called the index stay).

The program applies to six (6) different diagnosis cohorts (i.e., they fall into one of these groups at their initial or index hospitalization): AMI, CABG, COPD, HF, HIP-KNEE, PN

AMI = Acute myocardial infarction
CABG = Coronary artery bypass graft
COPD = Chronic obstructive pulmonary disease
HF = heart failure
HIP-KNEE = Total hip or knee replacement
PN = Pneumonia

The specific datasets used are:

* [Hospital General Information](https://data.cms.gov/provider-data/dataset/xubh-q36u): Provides information on hospitals such as state, location, etc.
* [Hospital Readmissions Reduction Program](https://data.cms.gov/provider-data/dataset/9n3s-kdb3): Contains readmission program metrics for each hospital participating in the program

# Data Description For App

The dataset used in the application contains one row per hospital-diagnosis group combination, providing the program metrics for that diagnosis group for that hospital.

## Hospital information fields

These are the main fields of importance for identifying hospital-specific information in the dataset.

* A unique hospital is identified by the `FacilityID` field.
* The `FacilityName` is the hospital name
* The `Address` column provides the street address for the hospital
* The `City` column provides the city that the hospital resides
* The `County` column provides the county that the hospital resides
* The `Zip` column provides the zip code that the hospital resides

Keep in mind that a single hospital has multiple rows in the dataset (for each of the diagnosis groups they had program metrics for).

*Important Note:*: The hospital information fields are all in capital letters (all characters), so queries on this data should always capitalize all characters when searching for specific cities or counties.

## HRRP program metrics

These are the fields in the dataset related to the HRRP program.

* The `DiagnosisCategory` column identifies the cohort/diagnosis group in which the subsequent program metrics apply for that hospital
* The `Excess` column is the _excess readmission ratio_, which is the _predicted readmission rate_ (`Predicted` column) divided by the _expected readmission rate_ (`Expected column`). This measures the magnitude of readmissions the hospital had in excess relative to what would be expected for the average hospital given their specific case mix.
* The `Predicted` column is the _predicted readmission rate_, which is interpreted as the projected readmission rate for that specific hospital for the group of patients in the associated `DiseaseCategory`
* The `Expected` column is the _expected readmission rate_, which is interpreted as the projected readmission rate for the average hospital for the group of patients in the associated `DiseaseCategory`
