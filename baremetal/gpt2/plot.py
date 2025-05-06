import pandas as pd
import plotly.express as px
import argparse

parser = argparse.ArgumentParser(description="Plotter Parameters")

parser.add_argument('--ib_hca_port', default='X8')
parser.add_argument('--nccl_oob_port', default='X8')
parser.add_argument('--gloo_tcp_port', default='X8')
parser.add_argument('--master_port', default='X8')
parser.add_argument('--x4mtu', type=int, default=1500)
parser.add_argument('--x8mtu', type=int, default=9000)
parser.add_argument('--nodes', nargs='+', type=int, default=[1, 2, 4, 8])
parser.add_argument('--comm_types', nargs='+', default=['tcp', 'rdma', 'gdrdma'])
parser.add_argument('--csv', default='baremetal.csv')
args = parser.parse_args()

columns = ['IB HCA Port', 'NCCL OOB Port', 'GLOO TCP Port', 'Master Port', 'X4 MTU', 'X8 MTU', 'Nodes', 'Communication Type', 'Grad Accum']
columns += [f'Step {i}' for i in range(3, 11)]
df = pd.read_csv(args.csv, usecols=columns)

criteria = {
    'IB HCA Port': args.ib_hca_port,
    'NCCL OOB Port': args.nccl_oob_port,
    'GLOO TCP Port': args.gloo_tcp_port,
    'Master Port': args.master_port,
    'X4 MTU': args.x4mtu,
    'X8 MTU': args.x8mtu
}
nodes_list = args.nodes
comm_types = args.comm_types

df_1n = df[df['Nodes'] == 1].copy()
df_1n['Label'] = 'Nodes: 1'

df_rest = df[df['Nodes'] > 1].copy()

for key, value in criteria.items():
    df_rest = df_rest[df_rest[key] == value]

df_rest = df_rest[df_rest['Nodes'].isin(nodes_list)]
df_rest = df_rest[df_rest['Communication Type'].isin(comm_types)]
df_rest['Label'] = 'Nodes: ' + df_rest['Nodes'].astype(str) + ' / ' + df_rest['Communication Type'].str.upper()

df_combined = pd.concat([df_1n, df_rest], ignore_index=True)

steps = [f'Step {i}' for i in range(3, 11)]
df_long = df_combined.melt(
    id_vars=['Grad Accum', 'Label'],
    value_vars=steps,
    var_name='Step',
    value_name='Step Time (ms)'
)

fig = px.scatter(
    df_long,
    x='Grad Accum',
    y='Step Time (ms)',
    color='Label',
    hover_data=['Step'],
    title='GPT2 Training Step Times'
)

fig.show()