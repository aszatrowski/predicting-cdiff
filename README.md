# Predicting *C. difficile* infection using machine learning
*Austin Szatrowski & Emily Shi*

*BIOS 26404: Machine Learning for Healthcare*

## Overview
This repository contains code for predicting *Clostridioides difficile* infection (CDI) using machine learning. Below we have listed where to look for different parts of our analysis. 


create_training_data_fullset.r: data processing and creation of training data 


model_dev_fullset.ipynb: model training for XGBmodels for 2, 7, and 30d, confidence validation for ICD-9 based versus ELISA-based labeling strategies, AUROC and AUPRC curve generation 


UNIMPUTED_model_dev_fullset.ipynb: same as above but for running XGB on UNIMPUTED data
