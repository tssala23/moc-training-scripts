import pandas as pd
import plotly.express as px
import statsmodels
import statsmodels.api as sm
import numpy as np
import sys

def get_oc_418():
    flist = ["oc_yes_profile_npods1_nprocs4.csv", \
	     "oc_yes_profile_npods2_nprocs4.csv", \
	     "oc_no_profile_npods4_nprocs4_d12.csv", \
	     "oc_no_profile_npods8_nprocs4_d12.csv"]
    df_oc = pd.concat([pd.read_csv(f) for f in flist], axis=0)
    df_oc = df_oc[df_oc!="testlog"].copy()
    df_oc["color"] = df_oc.apply(lambda x: f'oc H100: num pods = {x["num_pods"]} num gpus = {x["num_procs"]}', axis=1)
    df_oc['protocol'] = 'TCP'
    df_oc["color_type"] = "oc 4.18"

    return df_oc

def get_oc_417():
    flist = ["oc_no_profile_npods1_nprocs4_oc417.csv", \
	     "oc_no_profile_npods2_nprocs4_oc417.csv", \
	     "oc_no_profile_npods4_nprocs4_oc417.csv", \
	     "oc_no_profile_npods8_nprocs4_oc417.csv"]
    df_oc = pd.concat([pd.read_csv(f) for f in flist], axis=0)
    df_oc = df_oc[df_oc!="testlog"].copy()
    df_oc["color"] = df_oc.apply(lambda x: f'oc H100: num pods = {x["num_pods"]} num gpus = {x["num_procs"]}', axis=1)
    df_oc['protocol'] = 'TCP'
    df_oc["color_type"] = "oc 4.17"
    
    return df_oc

def get_bm():
    df_bm = pd.read_csv("gpt2_training_baremetal - per step data.csv")
    df_bm.columns = df_bm.iloc[0]
    df_bm = np.array(df_bm.iloc[1:].copy())
    
    bm = {'run_id': [],
	  'num_nodes': [],
	  'num_gpus': [],
	  'num_iter': [],
	  'grad_accum': [],
	  'time': []
	  }

    curr_exp = None
    for row in df_bm:
        if row[0] is not np.nan:
            curr_exp = row[0]
        assert len(row[2:])==10
        
        for grad_accum in range(1, 11):            
            bm['run_id'].append(curr_exp)
            bm['grad_accum'].append(grad_accum)
            bm['time'].append(row[1+grad_accum])
            
            bm['num_iter'].append(10)
            bm['num_gpus'].append(4)
            bm['num_nodes'].append(curr_exp.split('N')[1])

    df_bm = pd.DataFrame(bm)
    df_bm["color"] = df_bm.apply(lambda x: f'bm H100: num nodes = {x["num_nodes"]} num gpus = {x["num_gpus"]}', axis=1)
    df_bm['protocol'] = df_bm.run_id.apply(lambda x: x.split("N")[0].strip())
    df_bm['protocol'] = df_bm['protocol'].fillna('TCP')
    #------plot
    colmap = {'num_nodes': 'num_pods',
	      'num_gpus': 'num_procs'}
    df_bm.columns = [colmap.get(c, c) for c in df_bm.columns]
    df_bm = df_bm[~df_bm['protocol'].isin(['RDMA', 'GDRDMA'])]
    df_bm["color_type"] = "bm"
    
    return df_bm

if __name__=="__main__":
	df_oc_417 = get_oc_417()
	df_oc_418 = get_oc_418()
	df_bm = get_bm()
	
	df = pd.concat([df_bm, df_oc_417, df_oc_418], axis=0)
