#!/usr/bin/env bash

set -euo pipefail

OUT_LOC="${OUT_LOC:-/tmp/logs}"
mkdir -p "$OUT_LOC"

SAMP_PIDS=()

start_samplers() {
  #for g in $(nvidia-smi --query-gpu=index --format=csv,noheader); do
  #  stdbuf -oL -eL nvidia-smi dmon -s pucv -o DT -i "$g" > "$OUT_LOC/gpu${g}.dmon" 2>&1 & SAMP_PIDS+=("$!")
  #done
  stdbuf -oL -eL nvidia-smi dmon -s mte --gpm-metrics 20,21,60,61 -o DT --format csv > "$OUT_LOC/smi-metrics.dmon" 2>&1 & SAMP_PIDS+=("$!")

  ( while :; do
      echo "===== $(date -Is) =====" >> "$OUT_LOC/dmabuf.log"
      grep -RHEn 'exp(|orter)|attach|mlx5|nvidia' /sys/kernel/debug/dma_buf/ >> "$OUT_LOC/dmabuf.log" 2>/dev/null || true
      echo >> "$OUT_LOC/dmabuf.log"
      sleep 5
    done ) & SAMP_PIDS+=("$!")
}

cleanup_samplers() {
  ((${#SAMP_PIDS[@]})) || return 0
  kill -TERM "${SAMP_PIDS[@]}" 2>/dev/null || true
  wait "${SAMP_PIDS[@]}" 2>/dev/null || true
}

forward() {
  kill -TERM "$PID" 2>/dev/null || true
}

trap forward INT TERM
trap cleanup_samplers EXIT

start_samplers
./run.sh "$@" &
PID=$!
wait "$PID"
RETVAL=$?

# stop samplers before holding
cleanup_samplers

trap "exit $RETVAL" INT TERM
#while :; do sleep 3600; done

sleep infinity
