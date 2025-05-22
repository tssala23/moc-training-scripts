import pandas as pd
import plotly.express as px

import plotly.express as px
df = pd.read_csv("bm_iperf.csv")

def check(df):
    assert len(df.mtu.unique())==1
    assert len(df.ws.unique())==1
    assert len(df.br.unique())==1
    assert len(df.par.unique())==1
    assert df.prot.unique()[0]=="tcp"

def plot(df, yaxis="log"):
    check(df)
    fig = px.histogram(df, x="Bandwidth", color="affin", pattern_shape="role")
    if yaxis=="log":
        fig.update_yaxes(type="log")

    return fig
