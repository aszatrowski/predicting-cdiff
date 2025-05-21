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
- [x] Load liver fxn data
    - bilirubin direct (`item_id` 50838, LOINC ?)
    - alkaline phosphatase direct (ALP, `item_id` 50863, LOINC `6768-6`)
    - alanine transaminase direct (ALT, `item_id` 50861, LOINC `1742-6`)
    - aspartate aminotransferase (AST, `item_id` 50878, LOINC `1920-8`)
    - Gamma-glutamyltransferase (GLT, `item_id` 50927, LOINC `2324-2`)
    - [x] filter to prior to admin
    - [x] `pivot_wider()` such that each test as its own column, and Ab-prior tests are averaged
        - [x] could even include max? min? - whole set of summary stats done
- [x] Load blood counts data
    - [x] filter to prior to admin
- [x] Load renal fxn data
    - [x] filter to prior to admin
- [ ] MISSINGNESS IMPUTATION
    - [x] Mean imputation
    - [x] Median imputation
    - [x] Try kNN - failed
- [ ] ~~Load comorbidities data (ICD codes)~~
    - [ ] filter to prior admissions; ICDs don't have attached datetimes anyway
- [ ] Figure out how to handle dosage
     - [x] For now, just antibiotic class
     - [x] BBJ says count everything that's timestamped within an hour as a single administration, and then count doses, but idk if that exactly works 
- [x] Large data handling with `BigQuery` - should no longer be necessary now that Midway is up and running
    - best idea so far: rewrite (Claude) data wrangling pipeline to SQL, then pass that in Google Cloud for each source CSV and then export those results, merge, train/test etc.
    - If BBJ can get us Midway access, that would also be good, since we can just `wget` the whole dataset there and train using their compute
        - update: Midway access likely. Store the data up there, have all the groups share a copy, and then we can use Midway compute for model training and we won't have to worry about fitting the whole training dataset in RAM 
- [x] MIMIC-III Clinical on Midway
- [x] First XGBoost training run on demo dataset
    - [x] Create train/validation/test subsets
        - `sklearn.train_test_split()`
        - k-fold cross validation probably a good idea
- [ ] First logistic regression training run on demo dataset
- [ ] Simple logistic regression for `cdiff_flag ~ admin_time_since_admit`
    - because Austin is curious
- [ ] Select final feature set 
- [x] `git pull` on Midway
- [x] Run data pull on Midway
- [ ] Implement logistic regression on Midway
    - Check OR
- [x] Implement XGBoost on Midway
- [x] Figure out model evaluation; will be AUPRC given low case prevalence
    - both AUROC and AUPRCs computed for prediction periods
- [ ] Sensitivity analyses:
    - [x] Timing
        - [ ] ~~1 day~~
        - [x] 2 days
        - [x] 7 days
        - [x] 30 days
    - [ ] Label formula
    - [ ] ~~With/without gamma-glutamyltransferase (only 1 non-missing value)~~
- [ ] Secondary endpoint: severe C. diff
    - [ ] Define label for this
    - [ ] Implement 
- [x] Survival analysis
    - `scikit-surv`
    - [x] fix survival flag 
    - [x] nice KM plot
    - [x] Cox PH model
    - [ ] classifier w cross validation and validation/test
- [ ] ~~Unsupervised clustering of cases for identifying cryptic C-diff?~~
    - Is case similarity sufficiently specific, or would this be dastardly falsely positive?
    - any way to follow up and validate?
### UPDATED TO COMPLETE BEFORE PRESENTATION 
#### Emily: 
- [ ] Maybe: Attempt different missingness imputation method (binary is_missing, to train on missing data) 
- [X] Optimize XGBclassifier
    - [X] Sensitivity analysis for test
    - [ ] Confidence validation for examining how much individual labels matter
- [ ] Maybe: Logistic regression model
- [ ] Start slides
- [ ] Research interpretability of features from models

#### Austin: 
- [x] Survival analysis
- [ ] Work on slides too
- [ ] maybe: severe c. diff
- [ ] maybe: random survival forests
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
    * Comorbidities - FROM PRIOR VISITS
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
