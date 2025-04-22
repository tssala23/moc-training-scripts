# moc-training-scripts
Some convenient scripts for running gpt-2 training experiments. Note: these are hacky and need cleaning/robustness.

#### Generating CSV files from output log files
* Keep all log files from a run in folder X
* `scripts/gen_csv.sh X` will grep through each file, dump filenames and timing measurements into a text file data/name.txt and create a csv file data/name.csv with columns extracted from the output filenames. name is constructed based on X. 

#### OpenShift
* `templates/` has multiple templates for running distributed torch jobs with and without nsys and with volumes mounted.
* `scripts/gen_yaml.sh` takes a template and some arguments (hard-coded in script or passed as arguments) and generated YAML files in a folder. It just seds a bunch of values in a chosen template file.
* `scripts/run_yaml.sh` runs all the Jobs specified by YAML files in a given folder. Note that a loop checks for each job's successful termination before launching the next job. 

* `yaml/debug_pod.yaml` runs a pod that can be ssh'ed into for debugging purposes. In particular, since it mounts the shared volume, it's useful to quickly look at log files and do basic analysis. Convenient to use: `alias debug="oc exec debug-pod -it -- /bin/ash"` (alpine image uses ash).

* Use `oc cp debug-pod:$FOLDER ./$LOCAL_FOLDER` to copy log files/profiles over. See `logs/` for example logs that can be used to generate CSVs.
