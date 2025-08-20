#!/bin/bash

set -ueo pipefail

LOC=$1

grep "step " $LOC/stdout_* | grep -v "1/10\|2/10"
