# %% [markdown]
# # Missing Data Imputation for `predicting-cdiff`
print("Loading packages...")
# %
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer, KNNImputer
from sklearn.model_selection import train_test_split
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
print("Splitting data...")
train_val_df, test_df = train_test_split(training_data_imputed_simple_df, test_size = 0.2, shuffle=True, random_state=0)
print("Done.")
print("Writing simple CSVs...")
training_data_imputed_simple_df.to_csv("training_data_imputed_simple_full.csv.gz", index=False)
train_val_df.to_csv("training_data_imputed_simple_TRAIN.csv.gz", index=False)
test_df.to_csv("training_data_imputed_simple_TEST.csv.gz", index=False)
print("Done.")

print("Setting kNN imputer...")
#knn_imputer = KNNImputer(missing_values=np.nan, n_neighbors=2, weights="uniform")
#knn_imputer.fit(X = training_data)
print("Done.")
print("Running kNN impute...")
#imputed_array_knn = knn_imputer.transform(training_data)
#training_data_imputed_kNN_df = pd.DataFrame(imputed_array_kNN, columns=training_data.columns, index=training_data.index)
print("Done.")

# %%
print("Writing kNN CSV...")
#training_data_imputed_kNN_df.to_csv("training_data_imputed_kNN_full.csv.gz", index=False)
print("Done.")
