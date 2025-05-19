# %% [markdown]
# # Missing Data Imputation for `predicting-cdiff`

# %%
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer, KNNImputer

# %%
training_data = pd.read_csv("training_data_30d.csv")
training_data  = training_data.fillna(np.nan)

# %%
# imputer = SimpleImputer(missing_values=np.nan, strategy="mean")
# imputer.fit(X = training_data)

knn_imputer = KNNImputer(missing_values=np.nan, n_neighbors=5, weights="uniform")
knn_imputer.fit(X = training_data)

# %%
imputed_array = knn_imputer.transform(training_data)
training_data_imputed_df = pd.DataFrame(imputed_array, columns=training_data.columns, index=training_data.index)
# training_data_imputed_df 

# %%
training_data_imputed_df.to_csv("training_data_imputed.csv")
# %%
