# OpenShift Client Python Examples

This directory contains example Python scripts demonstrating how to use the `openshift-client-python` library to execute commands on multiple OpenShift pods in parallel.

## Files

- `example_parallel_execution.py` - Main example script showing parallel command execution
- `requirements.txt` - Python package dependencies
- `README.md` - This documentation file

## Prerequisites

1. **Python 3.7+** installed on your system
2. **OpenShift cluster access** with appropriate permissions
3. **kubeconfig** file configured for your cluster

## Installation

1. Install the required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

2. Ensure your kubeconfig is properly configured:
   ```bash
   oc whoami
   ```

## Usage

### Basic Example

Run the example script with default settings:

```bash
python example_parallel_execution.py
```

### Configuration

Before running the script, modify the following variables in `example_parallel_execution.py`:

```python
# Change these to match your environment
namespace = "your-namespace"  # Your OpenShift namespace
commands = [
    {
        'namespace': namespace,
        'pod_name': 'your-pod-1',  # Replace with actual pod names
        'command': ['echo', 'Hello from pod1'],
        'container': None  # Or specify container name
    },
    {
        'namespace': namespace,
        'pod_name': 'your-pod-2',  # Replace with actual pod names
        'command': ['echo', 'Hello from pod2'],
        'container': None
    }
]
```

## Features

The example script demonstrates:

1. **OpenShift Client Connection** - Establishes connection to OpenShift cluster
2. **Parallel Execution** - Executes commands on multiple pods simultaneously
3. **Output Capture** - Captures stdout and stderr from each command
4. **File Output** - Saves command results to individual log files
5. **Error Handling** - Handles failures gracefully with detailed logging
6. **Progress Tracking** - Shows execution progress and timing

## Output

The script creates an `output/` directory containing log files for each command execution:

```
output/
├── pod1_1234567890.log
├── pod2_1234567890.log
└── ...
```

Each log file contains:
- Pod name and namespace
- Command executed
- Return code and success status
- Complete stdout output
- Any stderr output

## Customization

### Adding More Commands

To execute additional commands, add more entries to the `commands` list:

```python
commands.append({
    'namespace': namespace,
    'pod_name': 'another-pod',
    'command': ['your', 'command', 'here'],
    'container': 'container-name'  # Optional
})
```

### Changing Parallel Workers

Adjust the number of parallel workers:

```python
results = executor.execute_commands_parallel(commands, max_workers=4)
```

### Custom Output Directory

Change the output directory:

```python
output_files = executor.save_results_to_files(results, output_dir="my_output")
```

## Error Handling

The script includes comprehensive error handling:

- Connection failures to OpenShift cluster
- Pod not found errors
- Command execution failures
- File I/O errors

All errors are logged with detailed information to help with debugging.

## Security Considerations

- Ensure your kubeconfig has appropriate permissions
- The script will execute commands with the same permissions as your user
- Be careful when executing commands that modify system state
- Consider using read-only commands for testing

## Troubleshooting

### Common Issues

1. **ImportError: No module named 'openshift'**
   - Install the package: `pip install openshift-client-python`

2. **Authentication failed**
   - Check your kubeconfig: `oc whoami`
   - Ensure you're logged in: `oc login`

3. **Pod not found**
   - Verify pod names and namespace
   - Check pod status: `oc get pods -n <namespace>`

4. **Permission denied**
   - Ensure your user has exec permissions on the pods
   - Check RBAC policies

### Debug Mode

Enable debug logging by modifying the logging level:

```python
logging.basicConfig(level=logging.DEBUG)
```

## License

This example code is provided as-is for educational purposes. Modify as needed for your specific use case.
