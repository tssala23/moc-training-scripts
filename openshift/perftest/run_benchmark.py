#!/usr/bin/env python3

import argparse
import datetime
import os
import subprocess
import sys
import re

# ## ---------------------------------------------------------------------------
# ## Global Configuration
# ## Default values that can be overridden by command-line arguments.
# ## ---------------------------------------------------------------------------

CONFIG = {
    "MTU": 9000,
    "PORTS": ["18515", "18516", "18517", "18518"],
    "QPAIRS": 6,
    "GPUS": 4,
    "INTERFACES": ["eno5np0", "eno6np0", "eno7np0", "eno8np0"],
    "NICS": ["mlx5_2", "mlx5_3", "mlx5_4", "mlx5_5"],
    "PODS": ["sr4n1", "sr4n2"],
    "BENCHMARKS": ["ib_read_bw", "ib_write_bw", "ib_read_lat", "ib_write_lat"],
    "FLAGS_BASE": "-a -R -T 41 -F -x 3 -m 4096 --report_gbits "
}

# Global variable for the current log file path, updated during runtime
IPRF_LOG = ""

# ## ---------------------------------------------------------------------------
# ## Core Functions
# ## ---------------------------------------------------------------------------

def log(message: str):
    """Prints a message to stdout and appends it to the global log file."""
    timestamp = datetime.datetime.now().timestamp()
    log_message = f"{timestamp:.2f} perf : {message}"
    print(log_message)
    if IPRF_LOG:
        try:
            with open(IPRF_LOG, "a") as f:
                f.write(log_message + "\n")
        except IOError as e:
            print(f"Error writing to log file {IPRF_LOG}: {e}", file=sys.stderr)

def get_ips(host_pod: str) -> list[str]:
    """
    Executes 'ifconfig' on a pod to get IP addresses for configured interfaces.
    
    Args:
        host_pod: The name of the pod to execute the command on.

    Returns:
        A list of IP addresses corresponding to the interfaces in CONFIG.
    """
    host_ips = []
    print(f"\nFetching IPs for host pod: {host_pod}...")
    for interface in CONFIG["INTERFACES"]:
        try:
            cmd = f'oc exec {host_pod} -- ifconfig {interface}'
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, check=True, timeout=30
            )
            # Use regex to find the 'inet' address
            match = re.search(r"inet\s+((?:\d{1,3}\.){3}\d{1,3})", result.stdout)
            if match:
                ip = match.group(1)
                host_ips.append(ip)
                print(f"  ✅ Found IP {ip} for interface {interface}")
            else:
                host_ips.append("")
                print(f"  ❌ Could not find IP for interface {interface}")
        except subprocess.CalledProcessError as e:
            print(f"Error getting IP for {interface} on {host_pod}: {e.stderr.strip()}", file=sys.stderr)
            host_ips.append("")
        except subprocess.TimeoutExpired:
            print(f"Timeout trying to get IP for {interface} on {host_pod}", file=sys.stderr)
            host_ips.append("")
    return host_ips

def generate_commands(base_cmd: str, log_base: str, host_pod: str, client_pod: str, host_ips: list[str]):
    """
    Constructs and prints the server and client benchmark commands.
    This replicates the Bash script's behavior of printing, not executing, the commands.
    """
    print("\n--- 🚀 Server Commands to Run ---")
    for i, (nic, port) in enumerate(zip(CONFIG["NICS"], CONFIG["PORTS"])):
        logfile = f"{log_base}_{nic}_{port}_host.log"
        inner_cmd = f"'{base_cmd} -d {nic} -p {port}'"
        full_host_cmd = f"oc exec {host_pod} -- bash -c {inner_cmd} > {logfile} 2>&1 &"
        print(full_host_cmd)

    print("\n--- 🛰️ Client Commands to Run ---")
    for i, (nic, port) in enumerate(zip(CONFIG["NICS"], CONFIG["PORTS"])):
        host_ip = host_ips[i]
        if not host_ip:
            print(f"# Skipping client for NIC {nic} because host IP is missing.")
            continue
        logfile = f"{log_base}_{nic}_{port}_{host_ip}_client.log"
        inner_cmd = f"'{base_cmd} -d {nic} -p {port} {host_ip}'"
        full_client_cmd = f"oc exec {client_pod} -- bash -c {inner_cmd} > {logfile} 2>&1 &"
        print(full_client_cmd)

def run_benchmark(bm_op: str, use_gpu: bool, host_pod: str, client_pod: str, log_dir: str):
    """
    Manages the setup and command generation for a specific benchmark.
    """
    title = f"Benchmark: {bm_op} (GPU: {'Yes' if use_gpu else 'No'})"
    print(f"\n{'='*60}\n{title:^60}\n{'='*60}")
    
    host_ips = get_ips(host_pod)
    
    include_qps = bm_op in ["ib_read_bw", "ib_write_bw"]
    cmd_base = f"{bm_op} {CONFIG['FLAGS_BASE']}"
    
    if include_qps:
        for qp_exp in range(CONFIG["QPAIRS"]):
            qpair = 2**qp_exp
            ex_cmd_base = f"{cmd_base} -q {qpair}"
            print(f"\n--- Testing with QPairs: {qpair} ---")
            
            if use_gpu:
                for g in range(CONFIG["GPUS"]):
                    log_file_base = os.path.join(log_dir, f"perftest_gpu_{bm_op}_{CONFIG['MTU']}_{qpair}_gpu{g}")
                    gpu_cmd_base = f"{ex_cmd_base} --use_cuda={g} --use_cuda_dmabuf"
                    generate_commands(gpu_cmd_base, log_file_base, host_pod, client_pod, host_ips)
            else: # CPU with QPs
                log_file_base = os.path.join(log_dir, f"perftest_{bm_op}_{CONFIG['MTU']}_{qpair}")
                generate_commands(ex_cmd_base, log_file_base, host_pod, client_pod, host_ips)
    else: # Benchmark does not include QPs
        if use_gpu:
            for g in range(CONFIG["GPUS"]):
                log_file_base = os.path.join(log_dir, f"perftest_gpu_{bm_op}_{CONFIG['MTU']}_gpu{g}")
                gpu_cmd_base = f"{cmd_base} --use_cuda={g} --use_cuda_dmabuf"
                generate_commands(gpu_cmd_base, log_file_base, host_pod, client_pod, host_ips)
        else: # CPU without QPs
            log_file_base = os.path.join(log_dir, f"perftest_{bm_op}_{CONFIG['MTU']}")
            generate_commands(cmd_base, log_file_base, host_pod, client_pod, host_ips)

# ## ---------------------------------------------------------------------------
# ## Main Execution Block
# ## ---------------------------------------------------------------------------

def main():
    """Parses arguments and runs the main benchmark loops."""
    global IPRF_LOG

    parser = argparse.ArgumentParser(
        description="A Python script to generate RDMA benchmark commands for OpenShift pods.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    
    def comma_list(string):
        return string.split(',')

    parser.add_argument("-p", "--ports", type=comma_list, help=f"Comma-separated port list.\nDefault: {CONFIG['PORTS']}")
    parser.add_argument("-n", "--pods", type=comma_list, help=f"Comma-separated pod list (host, client).\nDefault: {CONFIG['PODS']}")
    parser.add_argument("-i", "--interfaces", type=comma_list, help=f"Comma-separated interface list.\nDefault: {CONFIG['INTERFACES']}")
    parser.add_argument("-m", "--nics", type=comma_list, help=f"Comma-separated Mellanox device list.\nDefault: {CONFIG['NICS']}")
    parser.add_argument("-b", "--benchmarks", type=comma_list, help=f"Comma-separated benchmark list.\nDefault: {CONFIG['BENCHMARKS']}")
    parser.add_argument("-f", "--flags", help=f"Base flags string.\nDefault: \"{CONFIG['FLAGS_BASE']}\"")
    
    args = parser.parse_args()
    
    # Update CONFIG with any provided command-line arguments
    for key, value in vars(args).items():
        if value is not None:
            CONFIG[key.upper()] = value
            
    # Setup logging directories
    ts = datetime.datetime.now().strftime("%d-%m-%y-%H%M%S")
    log_dir_base = f"logs/run_{ts}"
    cpu_log_dir = os.path.join(log_dir_base, "cpu")
    gpu_log_dir = os.path.join(log_dir_base, "gpu")
    
    os.makedirs(cpu_log_dir, exist_ok=True)
    os.makedirs(gpu_log_dir, exist_ok=True)
    
    host_pod = CONFIG["PODS"][0]
    client_pod = CONFIG["PODS"][1]
    
    # --- Run CPU benchmarks ---
    IPRF_LOG = os.path.join(cpu_log_dir, "bmperf.log")
    log(f"Pods to be tested for CPU RDMA: {CONFIG['PODS']}")
    for benchmark in CONFIG["BENCHMARKS"]:
        run_benchmark(benchmark, use_gpu=False, host_pod=host_pod, client_pod=client_pod, log_dir=cpu_log_dir)
        
    # --- Run GPU benchmarks ---
    IPRF_LOG = os.path.join(gpu_log_dir, "bmperf.log")
    log(f"Pods to be tested for GPU RDMA: {CONFIG['PODS']}")
    for benchmark in CONFIG["BENCHMARKS"]:
        run_benchmark(benchmark, use_gpu=True, host_pod=host_pod, client_pod=client_pod, log_dir=gpu_log_dir)

    print(f"\n✅ All commands generated. Logs are being created in '{log_dir_base}'")

if __name__ == "__main__":
    main()
