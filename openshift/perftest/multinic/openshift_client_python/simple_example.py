#!/usr/bin/env python3
"""
Simple example using openshift-client-python to execute commands on two pods
and wait for completion, storing stdout to files.

This is a minimal example focusing on the core functionality.
"""

import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from openshift import client, config
    from openshift.dynamic import DynamicClient
except ImportError:
    print("Error: openshift-client-python not installed.")
    print("Install with: pip install openshift-client-python")
    exit(1)


def execute_command_on_pod(dynamic_client, namespace, pod_name, command, container=None):
    """
    Execute a command on a specific pod and return the result.
    
    Args:
        dynamic_client: OpenShift dynamic client
        namespace: Kubernetes namespace
        pod_name: Name of the pod
        command: Command to execute (list of strings)
        container: Container name (optional)
    
    Returns:
        Dictionary with stdout, stderr, and success status
    """
    try:
        # Get the pod resource
        v1_pods = dynamic_client.resources.get(api_version='v1', kind='Pod')
        
        # Execute the command
        response = v1_pods.connect_get_namespaced_pod_exec(
            name=pod_name,
            namespace=namespace,
            command=command,
            container=container,
            stderr=True,
            stdin=False,
            stdout=True,
            tty=False
        )
        
        # Read the response
        stdout = ""
        for line in response:
            if hasattr(line, 'decode'):
                line = line.decode('utf-8')
            stdout += line
        
        return {
            'pod_name': pod_name,
            'command': ' '.join(command),
            'stdout': stdout,
            'stderr': '',
            'success': True
        }
        
    except Exception as e:
        return {
            'pod_name': pod_name,
            'command': ' '.join(command),
            'stdout': '',
            'stderr': str(e),
            'success': False
        }


def save_output_to_file(result, output_dir="output"):
    """Save command result to a file."""
    os.makedirs(output_dir, exist_ok=True)
    
    timestamp = int(time.time())
    filename = f"{result['pod_name']}_{timestamp}.log"
    filepath = os.path.join(output_dir, filename)
    
    with open(filepath, 'w') as f:
        f.write(f"Pod: {result['pod_name']}\n")
        f.write(f"Command: {result['command']}\n")
        f.write(f"Success: {result['success']}\n")
        f.write("=" * 40 + "\n")
        f.write("STDOUT:\n")
        f.write(result['stdout'])
        f.write("\n" + "=" * 40 + "\n")
        f.write("STDERR:\n")
        f.write(result['stderr'])
        f.write("\n")
    
    return filepath


def main():
    """Main function - execute commands on two pods in parallel."""
    
    # Configuration - MODIFY THESE VALUES
    namespace = "default"  # Change to your namespace
    pod1_name = "pod1"    # Change to your first pod name
    pod2_name = "pod2"    # Change to your second pod name
    
    # Commands to execute
    commands = [
        {
            'namespace': namespace,
            'pod_name': pod1_name,
            'command': ['echo', 'Hello from pod1'],
            'container': None
        },
        {
            'namespace': namespace,
            'pod_name': pod2_name,
            'command': ['echo', 'Hello from pod2'],
            'container': None
        }
    ]
    
    try:
        # Connect to OpenShift
        print("Connecting to OpenShift cluster...")
        config.load_kube_config()
        k8s_client = client.ApiClient()
        dynamic_client = DynamicClient(k8s_client)
        print("Connected successfully!")
        
        # Execute commands in parallel
        print("Executing commands on pods...")
        results = []
        
        with ThreadPoolExecutor(max_workers=2) as executor:
            # Submit commands
            future_to_command = {}
            for cmd in commands:
                future = executor.submit(
                    execute_command_on_pod,
                    dynamic_client,
                    cmd['namespace'],
                    cmd['pod_name'],
                    cmd['command'],
                    cmd.get('container')
                )
                future_to_command[future] = cmd
            
            # Wait for completion
            for future in as_completed(future_to_command):
                result = future.result()
                results.append(result)
                print(f"Completed command on pod {result['pod_name']}")
        
        # Save results to files
        print("Saving results to files...")
        output_files = []
        for result in results:
            filepath = save_output_to_file(result)
            output_files.append(filepath)
            print(f"Saved output to {filepath}")
        
        # Print summary
        print("\n" + "=" * 50)
        print("EXECUTION SUMMARY")
        print("=" * 50)
        print(f"Total commands executed: {len(results)}")
        print(f"Successful commands: {sum(1 for r in results if r['success'])}")
        print(f"Failed commands: {sum(1 for r in results if not r['success'])}")
        print(f"Output files created: {len(output_files)}")
        
        # Print individual results
        for result in results:
            status = "SUCCESS" if result['success'] else "FAILED"
            print(f"\nPod {result['pod_name']}: {status}")
            if result['stdout']:
                print(f"  Output: {result['stdout'].strip()}")
            if result['stderr']:
                print(f"  Error: {result['stderr'].strip()}")
        
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
