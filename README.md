# moc-training-scripts
Some convenient scripts for running gpt-2 training experiments

#### Generating CSV files from output log files
* Keep all log files from a run in folder X
* `scripts/gen_csv.sh X` will grep through each file, dump filenames and timing measurements into a text file data/name.txt and create a csv file data/name.csv with columns extracted from the output filenames. name is constructed based on X. 
