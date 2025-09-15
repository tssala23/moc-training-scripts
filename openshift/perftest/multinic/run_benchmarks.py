import itertools
import subprocess
import re
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

# Creates combinations of lists
def generate_combinations(*lists):
  if not lists:
    return []
  return list(itertools.product(*lists))

# Runs host and client tests
def run_processes(host_command, host_logfilename, client_command, client_logfilename, waitForClient=True):
  if len(host_command) & len(host_logfilename) & len(client_command) & len(client_logfilename):
    filehandles=[]
    host_pids=[]
    client_pids=[]
    
    for hcmd, host_log, ccmd, client_log in zip(host_command, host_logfilename, client_command, client_logfilename):
      hfh = open(host_log, "w")
      cfh = open(client_log, "w")
      filehandles.append(hfh)
      filehandles.append(cfh)
    
      host_process = subprocess.Popen(
        hcmd,
        stdout=hfh,
      )
      host_pids.append(host_process)

      client_process = subprocess.Popen(
        ccmd,
        stdout=cfh,
      )
      client_pids.append(client_process)

    if waitForClient is True: 
      for cpid in client_pids:
          cpid.wait()
    for fh in filehandles:
      fh.close() 

if __name__ == "__main__":
  # Parameters that should be possible to pass through
  bw_tests = ['ib_write_bw', 'ib_read_bw']
  pods = ['sr4n1', 'sr4n2']
  gpus = [0, 1, 2, 3]
  queue_pairs = [1, 2, 4, 8, 16]
  devices = ['mlx5_2', 'mlx5_3', 'mlx5_4', 'mlx5_5']

  interfaces=("eno5np0", "eno6np0", "eno7np0", "eno8np0")
  ports=["18515", "18516", "18517", "18518"]
  flags_base = "-a -F -m 4096 --report_gbits"
  
  iface_ipaddr=[]

  affinity = [1, 0, 3, 2]

  if len(gpus) & len(devices) & len(ports) & len(interfaces) is not True:
     print("Number of GPUs, NICs, and ports must be equal") 

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

        for i, combination in enumerate(combinations):
            try:
                self._execute_single_test(combination, test_category, use_gpu, use_affinity)
            except Exception as e:
                print(f"Error in {test_category} test {i}: {e}")
                continue

    def _execute_single_test(self,
                           combination: Tuple,
                           test_category: str,
                           use_gpu: bool,
                           use_affinity: bool) -> None:
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
            queue_pair, host_gpu, client_gpu, use_gpu
        )

        run_processes(
            result['host_command'], result['host_logfile'],
            result['client_command'], result['client_logfile']
        )

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
                           use_gpu: bool) -> Dict[str, Any]:
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

        host_logfile = f"logs/perftest_{mode}_host_{test_name}{qp_str}_{host_pod}_{client_pod}_{host_device}{gpu_suffix}.log"
        client_logfile = f"logs/perftest_{mode}_client_{test_name}{qp_str}_{host_pod}_{client_pod}_{client_device}{gpu_suffix}.log"

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
            run_processes(
                result['host_command'], result['host_logfile'],
                result['client_command'], result['client_logfile']
            )
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
