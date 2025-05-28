# Predicting *C. difficile* infection using machine learning
Austin Szatrowski & Emily Shi

BIOS 26404: Machine Learning for Healthcare

## Overview
This repository contains code for predicting *Clostridioides difficile* infection (CDI) using machine learning. 

The files in our finalized pipeline are listed below. All other files are auxiliary or were not part of the final analysis. 

* `create_training_data_fullset.r`: data extraction from full MIMIC-III clinical, feature extraction, labeling, and generation of training dataframe

* `impute_split_fullset.py`: median imputation using `sklearn.preprocessing.SimpleImputer()`, then train-test split using `sklearn.model_selection.train_test_split()`

* `model_dev_fullset.ipynb`: model training for XGBmodels for 2, 7, and 30d, confidence validation for ICD-9 based versus ELISA-based labeling strategies, AUROC and AUPRC curve generation 

* `survival_analysis.ipynb`: fit and test the Cox model

* `plot_customization.ipynb`: generate AUROC, AUPRC, and feature importance plots for XGB & Cox models

* `random_survival_forests.ipynb`: fit and test the random survival forest classifier, plot time-dependent AUC

* `UNIMPUTED_model_dev_fullset.ipynb`: same as above but for running XGB on UNIMPUTED data

* `*.json`: Saved model parameters for each model

* `slurmsession_*.sh`: `sinteractive` commands for compute node interactive sessions