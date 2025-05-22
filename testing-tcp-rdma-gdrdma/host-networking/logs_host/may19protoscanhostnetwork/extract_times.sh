#!/bin/bash

grep -i step */stdout* | egrep -v "1/10|2/10" | awk '{split($1,array,"/"); split(array[2],array2,"_"); print array2[9], array2[11], $14}' | sed s:"("::g | egrep "[1-9]"

