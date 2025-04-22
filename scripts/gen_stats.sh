#!/bin/bash

set -ueo pipefail

LOC=$1

for f in $LOC/*.nsys-rep
do
	#nsys stats $f
	fname=`echo $f | sed s:"profile_":"stats_":g | sed s:".nsys-rep":"":g`
	echo $f
	echo $fname
	nsys stats $f >& $fname
done
