import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as gp

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

#remove tcp results on oc where NCCL_NTHREADS_PER_SOCKET and NCCL_SOCKS_PER_THREAD are not set
#generally use 16 and 4 for these params to be consistent with bare-metal
df = df[~((df['run_id']=='may19protoscanhostnetwork') & (df['type']=='tcp'))].copy() 

df.to_csv("csvs/agg.csv", index=False)

df_agg = df.groupby(["profile", "type", "env"]).agg({'time': ["mean", "std"]}).reset_index()
df_agg.columns = ['profile', 'type', 'env', 'time_mean', 'time_std']

df_agg["time_mean_label"] = df_agg["time_mean"].apply(lambda x: f'{x:.2f}ms')

fig = px.bar(df_agg[df_agg.profile==0], 
        x="type", 
        y="time_mean", 
        color="env", 
        barmode="group", 
        text="time_mean_label",
        error_y="time_std",
        title="Training time per Iteration/Batch in Bare-metal vs OpenShift",
        log_y=False)
fig.update_traces(textfont_size=24)
fig.update_layout(xaxis={'categoryorder': 'array', 
                         'categoryarray': ["tcp", "rdma", "gdr"]},
                  xaxis_title="Protocol Type",
                  yaxis_title="Time per Iteration/Batch (ms)"
                         )
fig.write_image("plots/comparison_training_time.png", height="800", width=1200)

