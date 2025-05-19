import pandas as pd
import plotly.express as px

df_tcp = pd.read_csv("tcp.csv", names=["name", "tcp"])
df_rdma = pd.read_csv("rdma.csv", names=["name", "rdma"])
df_gdr = pd.read_csv("gdr.csv", names=["name", "gdr"])

df_tcp.set_index("name", inplace=True)
df_rdma.set_index("name", inplace=True)
df_gdr.set_index("name", inplace=True)

df = pd.concat([df_tcp, df_rdma, df_gdr], axis=1)
