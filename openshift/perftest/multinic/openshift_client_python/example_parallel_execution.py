#!/usr/bin/env python3
"""
Example Python script using openshift-client-python to execute commands
on multiple pods in parallel and wait for completion.

This script demonstrates:
1. Connecting to OpenShift cluster
2. Executing commands on multiple pods simultaneously
3. Capturing stdout and stderr
4. Writing output to files
5. Waiting for all commands to complete

Requirements:
    pip install openshift-client-python

Usage:
    python example_parallel_execution.py
"""

import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Tuple, Dict, Any
import logging

try:
    from openshift import client, config
    from openshift.dynamic import DynamicClient
except ImportError:
    print("Error: openshift-client-python not installed.")
    print("Install with: pip install openshift-client-python")
    exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class OpenShiftCommandExecutor:
    """Class to handle OpenShift command execution on multiple pods."""
    
    def __init__(self, kubeconfig_path: str = None):
        """
        Initialize the OpenShift client.
        
        Args:
            kubeconfig_path: Path to kubeconfig file (optional)
        """
        try:
            # Load kubeconfig
            if kubeconfig_path:
                config.load_kube_config(config_file=kubeconfig_path)
            else:
                config.load_kube_config()
            
            # Create dynamic client
            k8s_client = client.ApiClient()
            self.dynamic_client = DynamicClient(k8s_client)
            
            logger.info("Successfully connected to OpenShift cluster")
            
        except Exception as e:
            logger.error(f"Failed to connect to OpenShift cluster: {e}")
            raise
    
    def execute_command_on_pod(self, 
                              namespace: str, 
                              pod_name: str, 
                              command: List[str],
                              container: str = None) -> Dict[str, Any]:
        """
        Execute a command on a specific pod.
        
        Args:
            namespace: Kubernetes namespace
            pod_name: Name of the pod
            command: Command to execute (list of strings)
            container: Container name (optional)
            
        Returns:
            Dictionary containing stdout, stderr, and return code
        """
        try:
            # Get the pod resource
            v1_pods = self.dynamic_client.resources.get(
                api_version='v1', 
                kind='Pod'
            )
            
            # Prepare the exec request
            exec_request = {
                'apiVersion': 'v1',
                'kind': 'Pod',
                'metadata': {
                    'name': pod_name,
                    'namespace': namespace
                },
                'spec': {
                    'containers': [{
                        'name': container or 'default',
                        'command': command
                    }]
                }
            }
            
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
            
            # Parse the response
            stdout = ""
            stderr = ""
            return_code = 0
            
            # The response is a stream, we need to read it
            for line in response:
                if hasattr(line, 'decode'):
                    line = line.decode('utf-8')
                stdout += line
            
            logger.info(f"Command executed successfully on pod {pod_name}")
            
            return {
                'pod_name': pod_name,
                'namespace': namespace,
                'command': ' '.join(command),
                'stdout': stdout,
                'stderr': stderr,
                'return_code': return_code,
                'success': True
            }
            
        except Exception as e:
            logger.error(f"Failed to execute command on pod {pod_name}: {e}")
            return {
                'pod_name': pod_name,
                'namespace': namespace,
                'command': ' '.join(command),
                'stdout': '',
                'stderr': str(e),
                'return_code': 1,
                'success': False
            }
    
    def execute_commands_parallel(self, 
                                 commands: List[Dict[str, Any]], 
                                 max_workers: int = 4) -> List[Dict[str, Any]]:
        """
        Execute multiple commands on different pods in parallel.
        
        Args:
            commands: List of command dictionaries
            max_workers: Maximum number of parallel workers
            
        Returns:
            List of results from all commands
        """
        results = []
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all commands
            future_to_command = {}
            for cmd in commands:
                future = executor.submit(
                    self.execute_command_on_pod,
                    cmd['namespace'],
                    cmd['pod_name'],
                    cmd['command'],
                    cmd.get('container')
                )
                future_to_command[future] = cmd
            
            # Wait for completion and collect results
            for future in as_completed(future_to_command):
                cmd = future_to_command[future]
                try:
                    result = future.result()
                    results.append(result)
                    logger.info(f"Completed command on pod {result['pod_name']}")
                except Exception as e:
                    logger.error(f"Command failed on pod {cmd['pod_name']}: {e}")
                    results.append({
                        'pod_name': cmd['pod_name'],
                        'namespace': cmd['namespace'],
                        'command': ' '.join(cmd['command']),
                        'stdout': '',
                        'stderr': str(e),
                        'return_code': 1,
                        'success': False
                    })
        
        return results
    
    def save_results_to_files(self, 
                             results: List[Dict[str, Any]], 
                             output_dir: str = "output") -> List[str]:
        """
        Save command results to files.
        
        Args:
            results: List of command results
            output_dir: Directory to save output files
            
        Returns:
            List of created file paths
        """
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        created_files = []
        
        for result in results:
            # Create filename based on pod name and timestamp
            timestamp = int(time.time())
            filename = f"{result['pod_name']}_{timestamp}.log"
            filepath = os.path.join(output_dir, filename)
            
            # Write output to file
            with open(filepath, 'w') as f:
                f.write(f"Pod: {result['pod_name']}\n")
                f.write(f"Namespace: {result['namespace']}\n")
                f.write(f"Command: {result['command']}\n")
                f.write(f"Return Code: {result['return_code']}\n")
                f.write(f"Success: {result['success']}\n")
                f.write("=" * 50 + "\n")
                f.write("STDOUT:\n")
                f.write(result['stdout'])
                f.write("\n" + "=" * 50 + "\n")
                f.write("STDERR:\n")
                f.write(result['stderr'])
                f.write("\n")
            
            created_files.append(filepath)
            logger.info(f"Saved output to {filepath}")
        
        return created_files


def main():
    """Main function demonstrating parallel command execution."""
    
    # Example configuration
    namespace = "default"  # Change this to your namespace
    
    # Define commands to execute on different pods
    commands = [
        {
            'namespace': namespace,
            'pod_name': 'pod1',  # Replace with actual pod names
            'command': ['echo', 'Hello from pod1'],
            'container': None
        },
        {
            'namespace': namespace,
            'pod_name': 'pod2',  # Replace with actual pod names
            'command': ['echo', 'Hello from pod2'],
            'container': None
        },
        {
            'namespace': namespace,
            'pod_name': 'pod1',
            'command': ['date'],
            'container': None
        },
        {
            'namespace': namespace,
            'pod_name': 'pod2',
            'command': ['whoami'],
            'container': None
        }
    ]
    
    try:
        # Initialize the executor
        executor = OpenShiftCommandExecutor()
        
        # Execute commands in parallel
        logger.info("Starting parallel command execution...")
        start_time = time.time()
        
        results = executor.execute_commands_parallel(commands, max_workers=2)
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # Save results to files
        output_files = executor.save_results_to_files(results)
        
        # Print summary
        logger.info(f"Execution completed in {execution_time:.2f} seconds")
        logger.info(f"Total commands executed: {len(results)}")
        logger.info(f"Successful commands: {sum(1 for r in results if r['success'])}")
        logger.info(f"Failed commands: {sum(1 for r in results if not r['success'])}")
        logger.info(f"Output files created: {len(output_files)}")
        
        # Print individual results
        for result in results:
            status = "SUCCESS" if result['success'] else "FAILED"
            logger.info(f"Pod {result['pod_name']}: {status}")
            if result['stdout']:
                logger.info(f"  Output: {result['stdout'].strip()}")
            if result['stderr']:
                logger.warning(f"  Error: {result['stderr'].strip()}")
        
    except Exception as e:
        logger.error(f"Script execution failed: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
