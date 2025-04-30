# Predicting *C. difficile* infection using machine learning
*Austin Szatrowski & Emily Shi*

*BIOS 26404: Machine Learning for Healthcare*

## Overview
This repository contains code for predicting *Clostridioides difficile* infection (CDI) using machine learning. 

## Task list
- [x] Define longitudinal structure
- [x] Load antibiotic administration data
    - [x] antibiotic classes
- [x] Load C. diff ELISA tests
- [x] Load C. diff ICD codes 
- [x] Load admissions data + patient demographics
- [x] Compute age & time since admit
- [x] Compute ICU context: is `icu_admit_time < antibiotic_time < icu_discharge_time == TRUE`?
- [ ] Load liver fxn data
    - bilirubin direct (`item_id` 50838, LOINC ?)
    - alkaline phosphatase direct (ALP, `item_id` 50863, LOINC `6768-6`)
    - alanine transaminase direct (ALT, `item_id` 50861, LOINC `1742-6`)
    - aspartate aminotransferase (AST, `item_id` 50878, LOINC `1920-8`)
    - Gamma-glutamyltransferase (GLT, `item_id` 50927, LOINC `2324-2`)
    - [x] filter to prior to admin
    - [x] `pivot_wider()` such that each test as its own column, and Ab-prior tests are averaged
        - could even include max? min?
- [ ] Load blood counts data
    - [ ] filter to prior to admin
- [ ] Load renal fxn data
    - [ ] filter to prior to admin
- [ ] Load comorbidities data
    - [ ] filter to prior to admin
- [ ] Figure out how to handle dosage
- [ ] Large data handling with `BigQuery`
    - best idea so far: rewrite (Claude) data wrangling pipeline to SQL, then pass that in Google Cloud for each source CSV and then export those results, merge, train/test etc.
    - If BBJ can get us Midway access, that would also be good, since we can just `wget` the whole dataset there and train using their compute
        - update: Midway access likely. Store the data up there, have all the groups share a copy, and then we can use Midway compute for model training and we won't have to worry about fitting the whole training dataset in RAM 
- [ ] Simple logistic regression for `cdiff_flag ~ admin_time_since_admit`
    - because Austin is curious
- [ ] Select final feature set 
- [ ] Create train/validation/test subsets
    - `sklearn.train_test_split()`
    - k-fold cross validation probably a good idea
    - MIMIC IV as test set? would be a nice forward comparison
- [ ] Implement logistic regression
    - Check OR
- [ ] Implement XGBoost
- [ ] Figure out model evaluation; will be AUPRC given low case prevalence
- [ ] Unsupervised clustering of cases for identifying cryptic C-diff?
    - Is case similarity sufficiently specific, or would this be dastardly falsely positive?
    - any way to follow up and validate?
- [ ] Final report in $\LaTeX$ (non-negotiable)

## Labels
Admission is labeled as CDI if:
* ELISA Positive OR
* ICD9: `008.45` OR
    * It is possible that ICDs don't actually have datetimes attached and are only finalized at the end of admission. For this reason I think we can require that `008.45` was marked at the end of an admission that ended <30 days from admin point.
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