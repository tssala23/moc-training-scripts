import itertools
import subprocess
import re
import argparse
import json
import yaml
import os
import time
import sys
import concurrent.futures
import multiprocessing
from datetime import datetime
from copy import deepcopy
from dataclasses import dataclass
from typing import List, Tuple, Optional, Dict, Any
from enum import Enum

# Constants
DEFAULT_FLAGS_BASE = "-a -R -T 41 -F -x 3 -m 4096 --report_gbits"
DEFAULT_QPAIRS = 5
DEFAULT_GPUS = 4

class TestType(Enum):
    CPU_BANDWIDTH = "cpu_bw"
    CPU_LATENCY = "cpu_lat"
    GPU_BANDWIDTH = "gpu_bw"
    GPU_LATENCY = "gpu_lat"
    AFFINITY_GPU_BANDWIDTH = "affinity_gpu_bw"
    AFFINITY_GPU_LATENCY = "affinity_gpu_lat"

@dataclass
class TestConfiguration:
    """Configuration for a single test run"""
    test_type: TestType
    host_pod: str
    client_pod: str
    host_device: str
    client_device: str
    queue_pair: Optional[int] = None
    host_gpu: Optional[int] = None
    client_gpu: Optional[int] = None
    use_affinity: bool = False

@dataclass
class CommandResult:
    """Result of command generation"""
    host_command: List[str]
    client_command: List[str]
    host_logfile: str
    client_logfile: str
    host_ip: str
    device_index: int

@dataclass
class BenchmarkConfig:
    """Configuration for benchmark parameters"""
    bw_tests: List[str]
    pods: List[str]
    gpus: List[int]
    queue_pairs: List[int]
    devices: List[str]
    interfaces: List[str]
    ports: List[str]
    flags_base: str
    affinity: List[int]

    @classmethod
    def from_dict(cls, config_dict: Dict[str, Any]) -> 'BenchmarkConfig':
        """Create BenchmarkConfig from dictionary"""
        return cls(
            bw_tests=config_dict.get('bw_tests', ['ib_write_bw', 'ib_read_bw']),
            pods=config_dict.get('pods', ['sr4n1', 'sr4n2']),
            gpus=config_dict.get('gpus', [0, 1, 2, 3]),
            queue_pairs=config_dict.get('queue_pairs', [1, 2, 4, 8, 16]),
            devices=config_dict.get('devices', ['mlx5_2', 'mlx5_3', 'mlx5_4', 'mlx5_5']),
            interfaces=config_dict.get('interfaces', ['eno5np0', 'eno6np0', 'eno7np0', 'eno8np0']),
            ports=config_dict.get('ports', ['18515', '18516', '18517', '18518']),
            flags_base=config_dict.get('flags_base', DEFAULT_FLAGS_BASE),
            affinity=config_dict.get('affinity', [1, 0, 3, 2])
        )

    @classmethod
    def load_from_file(cls, config_file: str) -> 'BenchmarkConfig':
        """Load configuration from JSON or YAML file"""
        try:
            with open(config_file, 'r') as f:
                if config_file.endswith('.yaml') or config_file.endswith('.yml'):
                    config_dict = yaml.safe_load(f)
                else:  # Assume JSON
                    config_dict = json.load(f)
            return cls.from_dict(config_dict)
        except Exception as e:
            raise ValueError(f"Error loading config file {config_file}: {e}")

    def validate(self) -> None:
        """Validate configuration parameters"""
        if len(self.gpus) != len(self.devices) or len(self.devices) != len(self.ports) or len(self.ports) != len(self.interfaces):
            raise ValueError("Number of GPUs, devices, ports, and interfaces must be equal")
        
        if not self.bw_tests:
            raise ValueError("At least one bandwidth test must be specified")
        
        if len(self.pods) < 2:
            raise ValueError("At least 2 pods must be specified")

# Creates combinations of lists
def generate_combinations(*lists):
  if not lists:
    return []
  return list(itertools.product(*lists))

def run_command(command: str, timeout: int):
    """
    A worker function that runs a single shell command and waits for it.
    This function is designed to be run in a separate thread.
    """
    try:
        # subprocess.run is a blocking call with its own timeout
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return {
            'stdout': result.stdout,
            'stderr': result.stderr,
            'returncode': result.returncode
        }
    except subprocess.TimeoutExpired as e:
        print(f"❌ Command timed out after {timeout} seconds: {command}")
        return {
            'stdout': e.stdout or '', # Output captured before timeout
            'stderr': e.stderr or '',
            'returncode': -1, # Custom code for timeout
            'error': 'TimeoutExpired'
        }

def run_commands_threaded(host_cmd: str, client_cmd: str, timeout: int):
    """
    Runs two shell commands in parallel using a thread pool.
    Each command is subject to the same individual timeout.
    """
    results = {}
    with concurrent.futures.ThreadPoolExecutor() as executor:
        # Submit each command to the thread pool
        future1 = executor.submit(run_command, host_cmd, timeout)
        future2 = executor.submit(run_command, client_cmd, timeout)

        # .result() waits for each future to complete and gets its return value
        results['host_result'] = future1.result()
        results['client_result'] = future2.result()
    
    return results

'''
def run_processes(host_command, host_logfilename, client_command, client_logfilename, waitForClient=True):
  if len(host_command) & len(host_logfilename) & len(client_command) & len(client_logfilename):
    filehandles=[]
    host_pids=[]
    client_pids=[]
    
    #for hcmd, host_log, ccmd, client_log in zip(host_command, host_logfilename, client_command, client_logfilename):
#    hfh = open(host_logfilename, "w")
#    cfh = open(client_logfilename, "w")
#    filehandles.append(hfh)
#    filehandles.append(cfh)

    final_results = run_commands_threaded(host_command, client_command, 60)
    with open(host_logfilename, "w") as hfh, open(client_logfilename, "w") as cfh:    
        hfh.write(final_results['host_result'].stdout)
        cfh.write(final_results['client_result'].stdout)
    return
    try:
      host_process = subprocess.Popen(
          host_command.split(' '),
          stdout=hfh,
      )
    except Exception as e:
      print(f"Host process Popen error: {e}")
      exit(1)
      
    host_pids.append(host_process)
    time.sleep(1)
    try:
      client_process = subprocess.Popen(
          client_command.split(' '),
          stdout=cfh
      )
    except Exception as e:
      print(f"Host process Popen error: {e}")
      exit(1)
      
    client_pids.append(client_process)

    client_process.wait()
    host_process.wait()
    cfh.close()
    hfh.close()

    #if waitForClient is True: 
    #for cpid in client_pids:
    #    cpid.wait()
    #for hpid in host_pids:
    #    hpid.wait()
    #for fh in filehandles:
    #  fh.close() 
'''

def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Run RDMA benchmark tests with configurable parameters",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Use default configuration
  python run_benchmarks.py

  # Use config file
  python run_benchmarks.py --config config.yaml

  # Override specific parameters
  python run_benchmarks.py --pods sr4n1,sr4n2 --devices mlx5_2,mlx5_3

  # Use config file with overrides
  python run_benchmarks.py --config config.yaml --queue-pairs 1,2,4
        """
    )

    # Config file option
    parser.add_argument(
        '--config', '-c',
        type=str,
        help='Path to configuration file (JSON or YAML)'
    )

    # Individual parameter options
    parser.add_argument(
        '--bw-tests',
        type=str,
        help='Comma-separated bandwidth tests (e.g., ib_read_bw,ib_write_bw)'
    )

    parser.add_argument(
        '--pods',
        type=str,
        help='Comma-separated pod names (e.g., sr4n1,sr4n2)'
    )

    parser.add_argument(
        '--gpus',
        type=str,
        help='Comma-separated GPU IDs (e.g., 0,1,2,3)'
    )

    parser.add_argument(
        '--queue-pairs',
        type=str,
        help='Comma-separated queue pair values (e.g., 1,2,4,8,16)'
    )

    parser.add_argument(
        '--devices',
        type=str,
        help='Comma-separated device names (e.g., mlx5_2,mlx5_3,mlx5_4,mlx5_5)'
    )

    parser.add_argument(
        '--interfaces',
        type=str,
        help='Comma-separated interface names (e.g., eno5np0,eno6np0,eno7np0,eno8np0)'
    )

    parser.add_argument(
        '--ports',
        type=str,
        help='Comma-separated port numbers (e.g., 18515,18516,18517,18518)'
    )

    parser.add_argument(
        '--flags-base',
        type=str,
        help='Base flags for benchmark commands'
    )

    parser.add_argument(
        '--affinity',
        type=str,
        help='Comma-separated affinity values (e.g., 1,0,3,2)'
    )

    return parser.parse_args()

def parse_comma_separated_list(value: str, type_func=int) -> List[Any]:
    """Parse comma-separated string into list of specified type"""
    if not value:
        return []
    return [type_func(item.strip()) for item in value.split(',')]

def create_config_from_args(args: argparse.Namespace) -> BenchmarkConfig:
    """Create BenchmarkConfig from command line arguments"""
    # Start with default config
    config_dict = {
        'bw_tests': ['ib_write_bw', 'ib_read_bw'],
        'pods': ['sr4n1', 'sr4n2'],
        'gpus': [0, 1, 2, 3],
        'queue_pairs': [1, 2, 4, 8, 16],
        'devices': ['mlx5_2', 'mlx5_3', 'mlx5_4', 'mlx5_5'],
        'interfaces': ['eno5np0', 'eno6np0', 'eno7np0', 'eno8np0'],
        'ports': ['18515', '18516', '18517', '18518'],
        'flags_base': DEFAULT_FLAGS_BASE,
        'affinity': [1, 0, 3, 2]
    }

    # Load from config file if specified
    if args.config:
        file_config = BenchmarkConfig.load_from_file(args.config)
        config_dict = {
            'bw_tests': file_config.bw_tests,
            'pods': file_config.pods,
            'gpus': file_config.gpus,
            'queue_pairs': file_config.queue_pairs,
            'devices': file_config.devices,
            'interfaces': file_config.interfaces,
            'ports': file_config.ports,
            'flags_base': file_config.flags_base,
            'affinity': file_config.affinity
        }

    # Override with command line arguments
    if args.bw_tests:
        config_dict['bw_tests'] = parse_comma_separated_list(args.bw_tests, str)
    
    if args.pods:
        config_dict['pods'] = parse_comma_separated_list(args.pods, str)
    
    if args.gpus:
        config_dict['gpus'] = parse_comma_separated_list(args.gpus, int)
    
    if args.queue_pairs:
        config_dict['queue_pairs'] = parse_comma_separated_list(args.queue_pairs, int)
    
    if args.devices:
        config_dict['devices'] = parse_comma_separated_list(args.devices, str)
    
    if args.interfaces:
        config_dict['interfaces'] = parse_comma_separated_list(args.interfaces, str)
    
    if args.ports:
        config_dict['ports'] = parse_comma_separated_list(args.ports, str)
    
    if args.flags_base:
        config_dict['flags_base'] = args.flags_base
    
    if args.affinity:
        config_dict['affinity'] = parse_comma_separated_list(args.affinity, int)

    return BenchmarkConfig.from_dict(config_dict)

if __name__ == "__main__":
    # Parse command line arguments
    args = parse_arguments()
    
    # Create configuration
    try:
        config = create_config_from_args(args)
        config.validate()
    except Exception as e:
        print(f"Configuration error: {e}")
        exit(1)

    # Extract parameters from config
    bw_tests = config.bw_tests
    pods = config.pods
    gpus = config.gpus
    queue_pairs = config.queue_pairs
    devices = config.devices
    interfaces = config.interfaces
    ports = config.ports
    flags_base = config.flags_base
    affinity = config.affinity

    print(f"Using configuration:")
    print(f"  Bandwidth tests: {bw_tests}")
    print(f"  Pods: {pods}")
    print(f"  GPUs: {gpus}")
    print(f"  Queue pairs: {queue_pairs}")
    print(f"  Devices: {devices}")
    print(f"  Interfaces: {interfaces}")
    print(f"  Ports: {ports}")
    print(f"  Flags base: {flags_base}")
    print(f"  Affinity: {affinity}")
    print()

    iface_ipaddr = []

    for pod in pods:
        pod_ifaces=[]
        pod_iface=["",""]
        get_ips_command = f"oc exec {pod} -- ifconfig".split(' ')
        result = subprocess.run(
                get_ips_command,
                capture_output=True,
                text=True,
                check=False
        )    
        pattern = r'eno[5-8]np0'
        lines = result.stdout.splitlines()
        found_match_on_previous_line = False

        for i, line in enumerate(lines):
            if found_match_on_previous_line:
                pod_iface[1]=line.strip().split(' ')[1]
                pod_ifaces.append(deepcopy(pod_iface)) 
                found_match_on_previous_line = False # Reset the flag
            
            if re.search(pattern, line):
                if i + 1 < len(lines): # Check if there's a next line
                    pod_iface[0]=line.strip().split(':')[0]
                    found_match_on_previous_line = True
        iface_ipaddr.append(deepcopy(pod_ifaces))

    def get_ipaddr(pod, device):
        podindex=pods.index(pod) # Find the pod index
        deviceindex=devices.index(device) # Find the device index
        iface=interfaces[deviceindex] # Get the interface name
        iflist=[row[0] for row in iface_ipaddr[podindex]] # Grab the first column
        ifindex=iflist.index(iface) # Find the interface index
        return iface_ipaddr[podindex][ifindex][1], deviceindex

    def get_affinity(device):
        devindex=devices.index(device)
        return affinity[devindex]

    # Permute the pods since commutativity does not necessarily apply
    host_client_pod_combinations = list(itertools.permutations(pods, 2))
    all_gpu_bw_combinations = generate_combinations(bw_tests, host_client_pod_combinations, devices, devices, queue_pairs, gpus, gpus)
    all_cpu_bw_combinations = generate_combinations(bw_tests, host_client_pod_combinations, devices, devices, queue_pairs)

    all_gpu_lat_combinations = generate_combinations(host_client_pod_combinations, devices, devices, gpus, gpus)
    all_cpu_lat_combinations = generate_combinations(host_client_pod_combinations, devices, devices)
    
    # For affinity cases we will assign the GPUs to the commands based on the selected NICs
    affinity_gpu_bw_combinations = generate_combinations(bw_tests, host_client_pod_combinations, devices, devices, queue_pairs)
    affinity_gpu_lat_combinations = generate_combinations(host_client_pod_combinations, devices, devices)

class BenchmarkTestRunner:
    """Unified test runner to eliminate code duplication in the 6 for loops"""

    def __init__(self,
                 flags_base: str = DEFAULT_FLAGS_BASE,
                 ports: Optional[List[int]] = None,
                 devices: Optional[List[str]] = None,
                 queue_pairs: Optional[List[int]] = None):
        self.flags_base = flags_base
        self.ports = ports or []
        self.devices = devices or []
        self.queue_pairs = queue_pairs or list(range(1, DEFAULT_QPAIRS + 1))

    def execute_test_batch(self,
                          combinations: List[Tuple],
                          test_category: str,
                          use_gpu: bool = False,
                          use_affinity: bool = False) -> None:
        """Execute a batch of tests with unified logic"""
        print(f"All {test_category} combinations")
        timestamp_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        dir_str = f"logs/{timestamp_str}/{test_category}"
        os.makedirs(dir_str, exist_ok=True)

        for i, combination in enumerate(combinations):
            try:
                self._execute_single_test(combination, test_category, use_gpu, use_affinity, dir_str)
            except Exception as e:
                print(f"Error in {test_category} test {i}: {e}")
                continue

    def _execute_single_test(self,
                           combination: Tuple,
                           test_category: str,
                           use_gpu: bool,
                           use_affinity: bool,
                           dir_str: str) -> None:
        """Execute a single test combination"""
        # Extract common parameters
        if test_category in ["CPU Bandwidth", "GPU Bandwidth", "Affinity GPU Bandwidth"]:
            test_name = combination[0]
            host_pod = combination[1][0]
            client_pod = combination[1][1]
            host_device = combination[2]
            client_device = combination[3]
            queue_pair = combination[4]
        else:  # Latency tests
            test_name = "ib_read_lat"
            host_pod = combination[0][0]
            client_pod = combination[0][1]
            host_device = combination[1]
            client_device = combination[2]
            queue_pair = None

        # Get GPU assignments
        host_gpu, client_gpu = self._get_gpu_assignments(combination, test_category, use_gpu, use_affinity)

        # Build commands and execute
        result = self._build_test_commands(
            test_name, host_pod, client_pod, host_device, client_device,
            queue_pair, host_gpu, client_gpu, use_gpu, dir_str
        )
        final_results = run_commands_threaded(
            result['host_command'][0], 
            result['client_command'][0], 
            60
        )
        with open(result['host_logfile'][0], "w") as hfh, open(result['client_logfile'][0], "w") as cfh:    
            hfh.write(final_results['host_result']['stdout'])
            cfh.write(final_results['client_result']['stdout'])
    
    def _get_gpu_assignments(self,
                           combination: Tuple,
                           test_category: str,
                           use_gpu: bool,
                           use_affinity: bool) -> Tuple[Optional[int], Optional[int]]:
        """Get GPU assignments based on test configuration"""
        if not use_gpu:
            return None, None

        if use_affinity:
            # Use affinity-based GPU assignment
            host_device = combination[2] if len(combination) > 2 else combination[1]
            client_device = combination[3] if len(combination) > 3 else combination[2]
            host_gpu = get_affinity(host_device)
            client_gpu = get_affinity(client_device)
        else:
            # Use explicit GPU assignment from combination
            if test_category in ["GPU Bandwidth", "GPU Latency"]:
                host_gpu = combination[5] if len(combination) > 5 else None
                client_gpu = combination[6] if len(combination) > 6 else None
            else:
                host_gpu = client_gpu = None

        return host_gpu, client_gpu

    def _build_test_commands(self,
                           test_name: str,
                           host_pod: str,
                           client_pod: str,
                           host_device: str,
                           client_device: str,
                           queue_pair: Optional[int],
                           host_gpu: Optional[int],
                           client_gpu: Optional[int],
                           use_gpu: bool,
                           dir_str: str) -> Dict[str, Any]:
        """Build host and client commands with proper configuration"""

        # Get IP address and device index
        host_ip, dev_index = get_ipaddr(host_pod, host_device)

        # Build base command parts
        host_cmd_parts = ["oc", "exec", host_pod, "--", test_name, self.flags_base]
        client_cmd_parts = ["oc", "exec", client_pod, "--", test_name, self.flags_base]

        # Add queue pairs for bandwidth tests
        if queue_pair and test_name in ["ib_read_bw", "ib_write_bw"]:
            host_cmd_parts.extend(["-q", str(queue_pair)])
            client_cmd_parts.extend(["-q", str(queue_pair)])

        # Add device specifications
        host_cmd_parts.extend(["-d", host_device, "-p", str(self.ports[dev_index])])
        client_cmd_parts.extend(["-d", client_device, "-p", str(self.ports[dev_index])])

        # Add GPU parameters
        if use_gpu and host_gpu is not None and client_gpu is not None:
            host_cmd_parts.extend(["--use_cuda=" + str(host_gpu), "--use_cuda_dmabuf"])
            client_cmd_parts.extend(["--use_cuda=" + str(client_gpu), "--use_cuda_dmabuf"])

        # Add IP to client command
        client_cmd_parts.append(host_ip)

        # Build log filenames
        mode = "gpu" if use_gpu else "cpu"
        qp_str = f"_{queue_pair}" if queue_pair else ""

        gpu_suffix = ""
        if use_gpu and host_gpu is not None and client_gpu is not None:
            gpu_suffix = f"_{host_gpu}_{client_gpu}"

        host_logfile = f"{dir_str}/perftest_{mode}_host_{test_name}{qp_str}_{host_pod}_{client_pod}_{host_device}{gpu_suffix}.log"
        client_logfile = f"{dir_str}/perftest_{mode}_client_{test_name}{qp_str}_{host_pod}_{client_pod}_{client_device}{gpu_suffix}.log"

        return {
            'host_command': [" ".join(host_cmd_parts)],
            'client_command': [" ".join(client_cmd_parts)],
            'host_logfile': [host_logfile],
            'client_logfile': [client_logfile]
        }

    def create_test_config_from_combination(self,
                                         combination: Tuple,
                                         test_category: str,
                                         use_gpu: bool = False,
                                         use_affinity: bool = False) -> TestConfiguration:
        """Create a TestConfiguration object from a combination tuple"""
        # Map test category to TestType
        test_type_map = {
            "CPU Bandwidth": TestType.CPU_BANDWIDTH,
            "CPU Latency": TestType.CPU_LATENCY,
            "GPU Bandwidth": TestType.GPU_BANDWIDTH,
            "GPU Latency": TestType.GPU_LATENCY,
            "Affinity GPU Bandwidth": TestType.AFFINITY_GPU_BANDWIDTH,
            "Affinity GPU Latency": TestType.AFFINITY_GPU_LATENCY,
        }

        test_type = test_type_map.get(test_category, TestType.CPU_BANDWIDTH)

        # Extract parameters based on test type
        if test_category in ["CPU Bandwidth", "GPU Bandwidth", "Affinity GPU Bandwidth"]:
            test_name = combination[0]
            host_pod = combination[1][0]
            client_pod = combination[1][1]
            host_device = combination[2]
            client_device = combination[3]
            queue_pair = combination[4]
        else:  # Latency tests
            test_name = "ib_read_lat"
            host_pod = combination[0][0]
            client_pod = combination[0][1]
            host_device = combination[1]
            client_device = combination[2]
            queue_pair = None

        # Get GPU assignments
        host_gpu, client_gpu = self._get_gpu_assignments(combination, test_category, use_gpu, use_affinity)

        return TestConfiguration(
            test_type=test_type,
            host_pod=host_pod,
            client_pod=client_pod,
            host_device=host_device,
            client_device=client_device,
            queue_pair=queue_pair,
            host_gpu=host_gpu,
            client_gpu=client_gpu,
            use_affinity=use_affinity
        )

    def run_test_from_config(self, config: TestConfiguration) -> None:
        """Run a test using a TestConfiguration object"""
        try:
            # Build commands
            result = self._build_test_commands(
                "ib_read_bw" if "bw" in config.test_type.value else "ib_read_lat",
                config.host_pod, config.client_pod, config.host_device, config.client_device,
                config.queue_pair, config.host_gpu, config.client_gpu,
                config.test_type in [TestType.GPU_BANDWIDTH, TestType.GPU_LATENCY,
                                   TestType.AFFINITY_GPU_BANDWIDTH, TestType.AFFINITY_GPU_LATENCY]
            )

            print(f"Running {config.test_type.value}: {config.host_device} -> {config.client_device}")
            final_results = run_commands_threaded(
                result['host_command'][0], 
                result['client_command'][0], 
                60
            )
            with open(result['host_logfile'][0], "w") as hfh, open(result['client_logfile'][0], "w") as cfh:    
                hfh.write(final_results['host_result']['stdout'])
                cfh.write(final_results['client_result']['stdout']) 
        except Exception as e:
            print(f"Error running test {config.test_type.value}: {e}")

# Main execution block
if __name__ == "__main__":
    # Create unified test runner instance
    test_runner = BenchmarkTestRunner(flags_base, ports, devices, queue_pairs)

    # Execute all test categories using the unified runner
    test_runner.execute_test_batch(all_cpu_bw_combinations, "CPU Bandwidth", use_gpu=False)
    test_runner.execute_test_batch(all_cpu_lat_combinations, "CPU Latency", use_gpu=False)
    test_runner.execute_test_batch(all_gpu_bw_combinations, "GPU Bandwidth", use_gpu=True)
    test_runner.execute_test_batch(all_gpu_lat_combinations, "GPU Latency", use_gpu=True)
    test_runner.execute_test_batch(affinity_gpu_bw_combinations, "Affinity GPU Bandwidth", use_gpu=True, use_affinity=True)
    test_runner.execute_test_batch(affinity_gpu_lat_combinations, "Affinity GPU Latency", use_gpu=True, use_affinity=True)
