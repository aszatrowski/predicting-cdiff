# %% [markdown]
# # Missing Data Imputation for `predicting-cdiff`
print("Loading packages...")
# %
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer, KNNImputer
print("Done.")

# %%
print("reading data...")
training_data = pd.read_csv("training_data_full.csv.gz")
# populate with np.NaN for compatibility with skl
training_data  = training_data.fillna(np.nan)
print("Done.")

# %%
print("Setting simple imputer...")
imputer = SimpleImputer(missing_values=np.nan, strategy="median")
imputer.fit(X = training_data)
print("Done.")

# %%
print("Running simple impute...")
imputed_array_simple = imputer.transform(training_data)
training_data_imputed_simple_df = pd.DataFrame(imputed_array_simple, columns=training_data.columns, index=training_data.index)
print("Done.")

print("Writing simple CSV...")
training_data_imputed_simple_df.to_csv("training_data_imputed_simple_full.csv.gz", index=False)
print("Done.")

print("Setting kNN imputer...")
# n_jobs to maximize parallelism
knn_imputer = KNNImputer(missing_values=np.nan, n_neighbors=2, weights="uniform", n_jobs=-1)
knn_imputer.fit(X = training_data)
print("Done.")
print("Running kNN impute...")
imputed_array_knn = knn_imputer.transform(training_data)
training_data_imputed_kNN_df = pd.DataFrame(imputed_array_kNN, columns=training_data.columns, index=training_data.index)
print("Done.")

# %%
print("Writing kNN CSV...")
training_data_imputed_kNN_df.to_csv("training_data_imputed_kNN_full.csv.gz", index=False)
print("Done.")
