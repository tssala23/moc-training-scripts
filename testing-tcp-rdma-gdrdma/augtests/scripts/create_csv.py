import os
import pandas as pd
import subprocess
import sys
import pathlib
import matplotlib.pyplot as plt
import plotly.express as px

def extract_raw_data(folder):
    out = subprocess.run([f'{os.path.dirname(__file__)}/create_csv.sh', folder], capture_output=True, text=True)

    return out.stdout #can do better error handling here

def process_text(text):
    def process_single_line(l):
        l = l.split()
        if len(l)==0:
            return {}

        ms_index = l.index('ms')
        time_index = ms_index - 1

        #time measurement entry
        time = float(l[time_index].replace("(",""))

        #extract experiment config from filename
        name = l[0]
        name_data = name.split("/")[-1].split(".")[0].split("_")

        data = {}
        data['time'] = time
        for elem in name_data: #loop over all fields
            if elem.find('npods')>-1:
                data['npods'] = int(elem.replace('npods',''))
            if elem.find('nprocs')>-1:
                data['nprocs'] = int(elem.replace('nprocs',''))
            if elem.find('profile')>-1:
                data['profile'] = int(elem.replace('profile',''))
            if elem.find('type')>-1:
                data['protocol'] = elem.replace('type','')
            if elem.find('numnics')>-1:
                data['numnics'] = int(elem.replace('numnics',''))
            if elem.find('runid')>-1:
                data['runid'] = elem.replace('runid','')
            if elem.find('nthreads')>-1:
                data['ncclnthreads'] = int(elem.replace('nthreads',''))
            if elem.find('nsocks')>-1:
                data['ncclnsocks'] = int(elem.replace('nsocks',''))
            if elem.find('bucketsize')>-1:
                data['bucketsize'] = int(elem.replace('bucketsize',''))
        return data

    data_list = []
    for line in text.split("\n"):
        data = process_single_line(line)
        data_list.append(data)

    return data_list

def plots(df):
    df.dropna(inplace=True)
    df['numnics'] = df['numnics'].astype(int)

    df.sort_values(by=['ncclnthreads', 'ncclnsocks'], ascending=True, inplace=True)

    df['Time (ms)'] = df['time']
    df['Number of Pods (and Nodes)'] = df['npods']
    df['Protocol'] = df['protocol']
    df['Number of CX7 NICs'] = df['numnics'].astype(str)
    df['Bucket Size (MiB)'] = df['bucketsize']
    df['NCCL_SOCKET_NTHREADS'] = df['ncclnthreads']
    df['NCCL_NSOCKS_PERTHREAD'] = df['ncclnsocks'].astype(str)

    df = df[df['time']<200]

    fig_list = []

    df_temp = df[df['numnics']==1]
    fig = px.scatter(df_temp, 
            x='NCCL_SOCKET_NTHREADS', 
            y='Time (ms)', 
            color='NCCL_NSOCKS_PERTHREAD',
            title='Time vs NCCL Parameters - TCP - #NICs=1')
    fig_list.append(fig)
    fig.write_image('time_vs_nccl_nic1.png', scale=1.5)

    df_temp = df[df['numnics']==4]
    fig = px.scatter(df_temp,
            x='NCCL_SOCKET_NTHREADS',
            y='Time (ms)',
            color='NCCL_NSOCKS_PERTHREAD',
            title='Time vs NCCL Parameters - TCP - #NICs=4')
    fig_list.append(fig)
    fig.write_image('time_vs_nccl_nic4.png', scale=1.5)

    for f in fig_list: f.show()

    return df, fig_list

if __name__=='__main__':
    folder = sys.argv[1]

    out = extract_raw_data(folder)

    out = process_text(out)

    df = pd.DataFrame(out)


