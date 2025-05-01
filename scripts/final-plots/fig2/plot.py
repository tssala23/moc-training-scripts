import pandas as pd
import numpy as np
import plotly.express as px

df = pd.read_csv("../../data/logs_profile0_ncclscan_npods2_nprocs4_oc417.csv")

df = df[df.grad_accum==1].copy()

df["prod"] = df["ncclnthreads"] * df["ncclsocksperthread"]

df.sort_values(by="ncclsocksperthread", ascending=True)

df["NCCL Sockets Per Thread"] = df["ncclsocksperthread"].astype(str)

df["NCCL NUM Socket Threads"] = df["ncclnthreads"]

fig = px.scatter(df, x="NCCL NUM Socket Threads", y="time", color="NCCL Sockets Per Thread",
        title=f"[OpenShift: GRAD ACCUM=1, TCP, MTU=1500] Time per Iteration as a function of NCCL N SOCKET THREADS and N SOCKETS PER THREAD: Max Time={df.time.max()}ms Min Time={df.time.min()}ms")
fig

fig.write_image("final_nccl_scan_oc.png", height=800, width=1500, scale=1.0)

