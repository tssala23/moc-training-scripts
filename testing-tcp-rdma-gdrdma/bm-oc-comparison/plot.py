import pandas as pd
import numpy as np

df_bm_np = pd.read_csv("csvs/bm_noprofile.csv")
df_bm_np['profile'] = 0
df_bm_np['env'] = 'bm'

df_bm_p = pd.read_csv("csvs/bm_profile.csv")
df_bm_p['profile'] = 1
df_bm_p['env'] = 'bm'

df_bm = pd.concat([df_bm_np, df_bm_p], axis=0)
df_bm['type'] = df_bm['type'].apply(lambda x: "gdr" if x=="gdrdma" else x)

flist = ["csvs/oc_may19_profile0.csv",\
         "csvs/oc_may19_profile1.csv",\
         "csvs/oc_may21_profile0.csv",\
         "csvs/oc_may21_profile1.csv"]
df_oc = pd.concat([pd.read_csv(f) for f in flist], axis=0)
df_oc['env'] = 'oc'

df = pd.concat([df_bm, df_oc], axis=0)
df['type'] = df['type'].str.lower()

df.to_csv("csvs/agg.csv", index=False)
