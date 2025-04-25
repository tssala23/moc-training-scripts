import pandas as pd

colnames = ["nelems", "time"]

df1 = pd.read_csv("alloc-only.ssv", sep=" ", names=colnames)
df1["type"]="alloc-only"
meds_alloc = df1.groupby("nelems")["time"].median()

df2 = pd.read_csv("alloc-allreduce.ssv", sep=" ", names=colnames)
df2["type"] = "alloc-allreduce"
meds_allreduce = df2.groupby("nelems")["time"].median()

print("\nmedian times for alloc only")
print(meds_alloc)

print("\nmediantimes for alloc + all-reduce")
print(meds_allreduce)

print("\ndifference = all-reduce only")
print(meds_allreduce-meds_alloc)

#df = pd.concat([df1, df2], axis=0)
