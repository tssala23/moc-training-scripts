FROM nvidia/cuda:12.0.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y python3 python3-pip

RUN pip3 install torch
RUN pip3 install numpy
RUN pip3 install tiktoken

RUN apt-get update
RUN apt-get install -y --no-install-recommends gnupg
RUN echo "deb https://developer.download.nvidia.com/devtools/repos/ubuntu2204/amd64 /" \
    > /etc/apt/sources.list.d/nvidia-devtools.list
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-get update
RUN apt install -y nsight-systems-cli

RUN apt-get install -y rdma-core ibverbs-providers infiniband-diags libmlx5-1 perftest iproute2 net-tools pciutils lsof ibverbs-utils vim git

WORKDIR /workspace
COPY torchrun_test.py /workspace/torchrun_test.py
COPY llm.c /workspace/llm.c

COPY run.sh /workspace/run.sh
RUN chmod u+x /workspace/run.sh

ENTRYPOINT ["/workspace/run.sh"]
