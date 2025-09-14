import itertools
import subprocess
import re
import time
from copy import deepcopy

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
  
  print("All CPU Bandwidth combinations")
  for i, c in enumerate(all_cpu_bw_combinations):
    test = c[0]
    host_pod = c[1][0]
    client_pod = c[1][1]
    host_device = c[2]
    client_device = c[3]
    queue_pair = c[4]
    flags = flags_base
    host_ip,dev_index = get_ipaddr(host_pod,host_device)
    host_command = f"oc exec {host_pod} -- {test} {flags} -q {queue_pair} -d {host_device} -p {ports[dev_index]}".split(' ')
    host_logfilename =  f"logs/perftest_cpu_host_{test}_{queue_pair}_{host_pod}_{client_pod}_{host_device}.log"
    client_command = f"oc exec {client_pod} -- {test} {flags} -q {queue_pair} -d {client_device} -p {ports[dev_index]} {host_ip}".split(' ') 
    client_logfilename =  f"logs/perftest_cpu_client_{test}_{queue_pair}_{host_pod}_{client_pod}_{client_device}.log"
    run_processes(host_command, host_logfilename, client_command, client_logfilename)

  print("All CPU Latency combinations")
  for i, c in enumerate(all_cpu_lat_combinations):
     test = "ib_read_lat"
     host_pod = c[0][0]
     client_pod = c[0][1]
     host_device = c[1]
     client_device = c[2]
     flags = flags_base
     host_command = f"oc exec {host_pod} -- {test} {flags} -d {host_device}".split(' ') 
     host_logfilename =  f"perftest_cpu_host_{test}_{host_pod}_{client_pod}_{host_device}.log"
     host_ip = get_ipaddr(host_pod,host_device)
     client_command = f"oc exec {client_pod} -- {test} {flags} -d {client_device} {host_ip}".split(' ')
     client_logfilename =  f"perftest_cpu_client_{test}_{host_pod}_{client_pod}_{client_device}.log"
     run_processes(host_command, host_logfilename, client_command, client_logfilename)
     
  print("All GPU Bandwidth combinations")
  for i, c in enumerate(all_gpu_bw_combinations):
    test = c[0]
    host_node = c[1][0]
    client_node = c[1][1]
    host_device = c[2]
    client_device = c[3]
    queue_pair = c[4]
    host_gpu = c[5]
    client_gpu = c[6]
    flags = flags_base
    host_command = f"oc exec {host_node} -- {test} {flags} -q {queue_pair} -d {host_device} --use_cuda={host_gpu} --use_cuda_dmabuf".split(' ') 
    host_logfilename =  f"perftest_gpu_host_{test}_{queue_pair}_{host_node}_{client_node}_{host_device}_{host_gpu}_{client_gpu}.log".split(' ')
    host_ip = get_ipaddr(host_pod,host_device)
    client_command = f"oc exec {client_node} -- {test} {flags} -q {queue_pair} -d {client_device} --use_cuda={client_gpu} --use_cuda_dmabuf {host_ip}".split(' ') 
    client_logfilename =  f"perftest_gpu_client_{test}_{queue_pair}_{host_node}_{client_node}_{client_device}_{host_gpu}_{client_gpu}.log".split(' ')
    run_processes(host_command, host_logfilename, client_command, client_logfilename)

  print("All GPU Latency combinations")
  for i, c in enumerate(all_gpu_lat_combinations):
    test = "ib_read_lat"
    host_node = c[0][0]
    client_node = c[0][1]
    host_device = c[1]
    client_device = c[2]
    host_gpu = c[3]
    client_gpu = c[4]
    flags = flags_base
    host_command = f"oc exec {host_node} -- {test} {flags} -q {queue_pair} -d {host_device} --use_cuda={host_gpu} --use_cuda_dmabuf".split(' ') 
    host_logfilename =  f"perftest_gpu_host_{test}_{queue_pair}_{host_node}_{client_node}_{host_device}_{host_gpu}_{client_gpu}.log".split(' ')
    host_ip = get_ipaddr(host_pod,host_device)
    client_command = f"oc exec {client_node} -- {test} {flags} -q {queue_pair} -d {client_device} --use_cuda={client_gpu} --use_cuda_dmabuf {host_ip}".split(' ') 
    client_logfilename =  f"perftest_gpu_client_{test}_{queue_pair}_{host_node}_{client_node}_{client_device}_{host_gpu}_{client_gpu}.log".split(' ')
    run_processes(host_command, host_logfilename, client_command, client_logfilename)

  print("Affinity GPU Bandwidth combinations")
  for i, c in enumerate(affinity_gpu_bw_combinations):
    test = c[0]
    host_node = c[1][0]
    client_node = c[1][1]
    host_device = c[2]
    client_device = c[3]
    queue_pair = c[4]
    host_gpu = get_affinity(host_device)
    client_gpu = get_affinity(client_device)
    flags = flags_base
    host_command = f"oc exec {host_node} -- {test} {flags} -q {queue_pair} -d {host_device} --use_cuda={host_gpu} --use_cuda_dmabuf".split(' ') 
    host_logfilename =  f"perftest_gpu_host_{test}_{queue_pair}_{host_node}_{client_node}_{host_device}_{host_gpu}_{client_gpu}.log".split(' ')
    host_ip = get_ipaddr(host_pod,host_device)
    client_command = f"oc exec {client_node} -- {test} {flags} -q {queue_pair} -d {client_device} --use_cuda={client_gpu} --use_cuda_dmabuf {host_ip}".split(' ') 
    client_logfilename =  f"perftest_gpu_client_{test}_{queue_pair}_{host_node}_{client_node}_{client_device}_{host_gpu}_{client_gpu}.log".split(' ')
    run_processes(host_command, host_logfilename, client_command, client_logfilename)

  print("Affinity GPU Latency combinations")
  for i, c in enumerate(affinity_gpu_lat_combinations):
    test = "ib_read_lat"
    host_node = c[0][0]
    client_node = c[0][1]
    host_device = c[1]
    client_device = c[2]
    host_gpu = get_affinity(host_device)
    client_gpu = get_affinity(client_device)
    flags = flags_base
    host_command = f"oc exec {host_node} -- {test} {flags} -q {queue_pair} -d {host_device} --use_cuda={host_gpu} --use_cuda_dmabuf".split(' ') 
    host_logfilename =  f"perftest_gpu_host_{test}_{queue_pair}_{host_node}_{client_node}_{host_device}_{host_gpu}_{client_gpu}.log".split(' ')
    host_ip = get_ipaddr(host_pod,host_device)
    client_command = f"oc exec {client_node} -- {test} {flags} -q {queue_pair} -d {client_device} --use_cuda={client_gpu} --use_cuda_dmabuf {host_ip}".split(' ') 
    client_logfilename =  f"perftest_gpu_client_{test}_{queue_pair}_{host_node}_{client_node}_{client_device}_{host_gpu}_{client_gpu}.log".split(' ')
    run_processes(host_command, host_logfilename, client_command, client_logfilename)
