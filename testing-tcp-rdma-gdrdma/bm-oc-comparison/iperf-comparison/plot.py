import pandas as pd
import plotly.express as px

import plotly.express as px

mapper = {"winsize": "ws", "protocol": "prot", "bufsize": "len", "bitrate": "br", "bw": "Bandwidth"}

def rename_cols(df):
    return df.rename(mapper, axis=1)

def check(df):
    assert len(df.mtu.unique())==1
    assert len(df.ws.unique())==1
    assert len(df.br.unique())==1
    assert len(df.par.unique())==1
    assert df.prot.unique()[0]=="tcp"

def plot(df, yaxis="log", title=None, subtitle=None):
    check(df)
    fig = px.histogram(df.sort_values(by="affin"), x="Bandwidth", color="affin", pattern_shape="role", title=title, subtitle=subtitle)
    if yaxis=="log":
        fig.update_yaxes(type="log")

    return fig

df_bm = pd.read_csv("bm_iperf.csv")
df_oc_100default = rename_cols(pd.read_csv("oc_iperf_100default.csv"))
df_oc_default = rename_cols(pd.read_csv("oc_iperf_default.csv"))
df_oc_nosleep = rename_cols(pd.read_csv("oc_iperf_nosleep.csv"))

#bare-metal plot
fig = plot(df_bm, yaxis="linear", title="Bare-metal Two Node iperf3 Bandwidth", subtitle=f'Max Bandwidth Achieved = {df_bm.Bandwidth.max().item()} Gb/s')
fig.update_layout(
    xaxis_title="Bandwidth (Gb/s)",
    yaxis_title="Counts"
        )
fig.write_image("plots/bm_bwdist.png", height=800, width=1200)

#oc plot
fig = plot(df_oc_default, yaxis="linear", title="Open-shift Two Debug-node (i.e. bare-metal-like) iperf3 Bandwidth", subtitle=f'Max Bandwidth Achieved = {df_oc_default.Bandwidth.max().item()} Gb/s')
fig.update_layout(
    xaxis_title="Bandwidth (Gb/s)",
    yaxis_title="Counts"
        )
fig.write_image("plots/oc_bwdist.png", height=800, width=1200)

#oc 100 trials (1 affinity) plot
fig = plot(df_oc_100default, yaxis="linear", title="Open-shift Two Debug-node (i.e. bare-metal-like) iperf3 Bandwidth", subtitle=f'Max Bandwidth Achieved = {df_oc_100default.Bandwidth.max().item()} Gb/s (ONLY CLOSE AFFINITY)')
fig.update_layout(
    xaxis_title="Bandwidth (Gb/s)",
    yaxis_title="Counts"
        )
fig.write_image("plots/oc_100trials_bwdist.png", height=800, width=1200)

