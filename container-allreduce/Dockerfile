FROM nvidia/cuda:12.0.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y python3 python3-pip

RUN pip3 install torch
RUN pip3 install numpy

WORKDIR /workspace
COPY run.sh /workspace/run.sh
COPY ar.py /workspace/ar.py

COPY iperf3 /root

RUN chmod u+x /workspace/run.sh

ENTRYPOINT ["/workspace/run.sh"]
