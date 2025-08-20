#!/bin/bash

set -ueo pipefail

TAG=${1:-start}
OUT_LOC=${OUT_LOC:-/tmp/logs}
mkdir -p $OUT_LOC

timestamp() { date -Is; }

#nstat
{
	echo "==== $(timestamp) : nstat ($TAG) ===="
	nstat -az
	echo

} > $OUT_LOC/nstat_${TAG}

#infiniband counters
for f in /sys/class/infiniband/mlx5_{2,3,4,5}/ports/1/counters
do
	[ -d $f ] || continue

	dev=`basename $(dirname $(dirname $(dirname $f)))`
	cat $f/port_xmit_data	 > $OUT_LOC/${dev}_xmit_data_${TAG} || true
	cat $f/port_rcv_data 	 > $OUT_LOC/${dev}_rcv_data_${TAG} || true
        cat $f/port_xmit_packets > $OUT_LOC/${dev}_xmit_packets_${TAG} || true
        cat $f/port_rcv_packets  > $OUT_LOC/${dev}_rcv_packets_${TAG} || true

	ls "/sys/class/infiniband/${dev}/device/net" 2>/dev/null | xargs -r echo > "$OUT_LOC/${dev}_netdevs_${TAG}" || true
done
