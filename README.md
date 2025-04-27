# Predicting *C. difficile* infection using machine learning
*Austin Szatrowski & Emily Shi*

*BIOS 26404: Machine Learning for Healthcare*

## Overview
This repository contains code for predicting *Clostridioides difficile* infection (CDI) using machine learning. 

## Task list
- [x] Define longitudinal structure
- [x] Load antibiotic administration data
- [x] Load C. diff ELISA tests
- [x] Load C. diff ICD codes 
- [ ] Load admissions data + patient demographics
    - [ ] Join to antibiotic data 
- [ ] Load comorbidities data

## Labels
Admission is labeled as CDI if:
* ELISA Positive OR
* ICD9: `008.45` OR
* Both:
    * PCR Positive 
    * Diarrhea NOS (`787.91`)


##  Longitudinal Data Structure
* Unit of analysis: 1 admission (1 patient may have multiple admissions)
* For each admission, identify first instance of antibiotic use with datetime
* Time window: datetime + 30 days
* Left join ICDs and ELISA tests to admissions, each with datetime
* IF datetime of any is < 30 days from datetime of antibiotic use, then label as CDI
    * otherwise label as non-CDI
* This will be the labels dataframe, simply $n$ admissions x 1 label
* Next: for each hospital admission, add features (with datetime prior to antibiotic use):
    * Demographics:
        * Age 
        * Sex 
    * Prior C. diff 
    * Days elapsed since admission
        * **Very important note:** Ab admin times only have day resolution, whereas admit times have minute resolution. If Abs were administered on admission day, the time comes out negative (e.g. 00:00 - 13:41). For now, I have rounded them up to zero.
    * TYPE of antibiotic
        * Classify each antibiotic instance into its class
        * Then pivot_wider to get a binary column for each class 
    * DOSE of antibiotic (?)
    * Care setting: when antibiotic was given, was pateint in ICU?
        * Simply check whether `icu_admit_time < antibiotic_time < icu_discharge_time`
    * Comorbidities
        * Diabetes
        * Hypertension
        * Chronic kidney disease
        * Congestive heart failure
        * Chronic lung disease
        * Liver disease
    * Blood counts
        * Hemoglobin
        * Platelets
        * WBC
    * Liver function tests
        * AST
        * ALT
        * ALP
        * Bilirubin
    * Renal function tests
        * Creatinine
        * eGFR 