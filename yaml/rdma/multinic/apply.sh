#!/bin/bash

YAML_LOC=yamls

for yaml in $YAML_LOC/*
do
	echo $yaml
	oc apply -f $yaml
done
