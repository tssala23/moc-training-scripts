#!/bin/bash

set -ueo pipefail

pattern=$1

#oc logs -f torchrun-multipod-1 > pod-1
grep Nelem $pattern* | awk  '{split($3,array,"="); split($5,array2,"="); print array[2], array2[2]}' | sed s:"_":"":g | sed s:"ms"::g
