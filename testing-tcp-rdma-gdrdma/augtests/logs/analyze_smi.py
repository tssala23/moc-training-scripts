import pandas as pd
import glob

def clean_files(smi_pattern):
    fnames = glob.glob(smi_pattern)
    print(fnames)

    df_dict = {}
    for f in fnames:
        with open(f) as file:
            lines = file.readlines()
        data = []
        count = 0
        for idx, l in enumerate(lines):
            if (l.find('gpu')>-1 or l.find('YYYY')>-1) and count>0:
                count += 1
                continue
            data.append(l.rstrip("\n").replace("-", "0").split(","))
        df = pd.DataFrame(data[1:], columns=data[0])
        df_dict[f.split('/')[0]] = df

    return df_dict
