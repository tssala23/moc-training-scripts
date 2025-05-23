import pandas as pd
import plotly.express as px
import numpy as np

#data prep
df_bm_cpu = pd.read_csv("bm_perftest_cpu.csv")
df_bm_cpu["type"] = "cpu"
df_bm_cpu["env"] = "bm"

df_bm_gpu = pd.read_csv("bm_perftest_gpu.csv")
df_bm_gpu["type"] = "gpu"
df_bm_gpu["env"] = "bm"

df_oc_cpu = pd.read_csv("oc_perftest_cpu.csv")
df_oc_cpu["type"] = "cpu"
df_oc_cpu["env"] = "oc"

df_oc_gpu = pd.read_csv("oc_perftest_gpu.csv")
df_oc_gpu["type"] = "gpu"
df_oc_gpu["env"] = "oc"

df_cpu = pd.concat([df_bm_cpu, df_oc_cpu], axis=0)
df_gpu = pd.concat([df_bm_gpu, df_oc_gpu], axis=0)

value_vars = [ '2',
 '4',
 '8',
 '16',
 '32',
 '64',
 '128',
 '256',
 '512',
 '1024',
 '2048',
 '4096',
 '8192',
 '16384',
 '32768',
 '65536',
 '131072',
 '262144',
 '524288',
 '1048576',
 '2097152',
 '4194304',
 '8388608']

#flatten data
def flatten(df_cpu, qp=2, test="ib_read_bw"): #using this var name so don't have to change func def
    id_vars = ["test", "qp", "metric", "type", "env"]
    df_cpu_flat = pd.melt(df_cpu, 
                      value_vars=value_vars, #df_cpu.columns[6:29],
                      var_name="size", 
                      value_name="bw", 
                      id_vars=id_vars)

    df_cpu_filtered = df_cpu_flat[(df_cpu_flat.qp==qp) & (df_cpu_flat.metric=="avg") & (df_cpu_flat.test==test)]
    df_cpu_grouped = df_cpu_filtered.groupby(id_vars + ["size"]).agg({"bw": {"mean", "std"}}).reset_index()

    colnames = ["test", "qp", "metric", "type", "env", "size", "bw_mean", "bw_std"]
    df_cpu_grouped.columns = colnames

    return df_cpu_flat, df_cpu_grouped, df_cpu_filtered.groupby("env").max()["bw"].to_dict(), df_cpu_filtered

def plot(df_cpu_grouped, title=None, subtitle=None):
    fig = px.bar(df_cpu_grouped, x="size", y="bw_mean", error_y="bw_std", color="env", barmode="group", title=title, subtitle=subtitle)

    fig.update_layout(xaxis={'categoryorder': 'array',
                             'categoryarray': np.sort(df_cpu_grouped["size"].unique().astype(int)).astype(str)})
    return fig

#CPU plot
def plot_full(df_cpu, qp=2, test="ib_read_bw", test_type="Host-to-Host", outfile="plots/cpu_rdma_qp2_write.png"):
    df_cpu_flat, df_cpu_grouped, maxbw, df_cpu_filtered = flatten(df_cpu, qp=qp, test=test)

    fig = px.bar(df_cpu_grouped, x="size", 
                 y="bw_mean", 
                 error_y="bw_std", 
                 color="env", 
                 barmode="group", 
                 title=f"RDMA {test} (#queue-pairs={qp}) Perftest {test_type} Bandwidth Measurements",
                 subtitle=f"Max Bare-metal BW = {maxbw['bm']}Gbps - Max OpenShift BW = {maxbw['oc']}Gbps")

    fig.update_layout(xaxis={'categoryorder': 'array',
                             'categoryarray': np.sort(df_cpu_grouped["size"].unique().astype(int)).astype(str)})


    fig.update_layout(
        xaxis_title="Size (Bytes)",
        yaxis_title="Mean Bandwidth (Gbps)"
        )

    fig.write_image(outfile, height=800, width=1200)
    
    return fig

for qp in [2, 4, 8, 16, 32]:
    for test in ["ib_read_bw", "ib_write_bw"]:
        fig = plot_full(df_cpu, qp=qp, test=test, test_type="Host-to-Host", outfile=f"plots/cpu_rdma_qp{qp}_{test}.png")
        fig = plot_full(df_gpu, qp=qp, test=test, test_type="GPU-to-GPU", outfile=f"plots/gpu_rdma_qp{qp}_{test}.png")
