# Modifying the base RHELAI image

Method based on [this](https://github.com/larsks/moc-bootc-rhelai-nvidia) repo. 

## Steps:
### 0: Ensure there is enough space in `root`
The default disk allocation for `root` is likely not going to be sufficient to store all the images needed. It is recommended to ensure there is sufficient space available before continuing. In the case of ESI on MOC, use the `moc-rhelai-nvidia-1.1` image instead of `rhelai` for deploying your nodes. For example:
```
metalsmith deploy --resource-class lenovo-sd665nv3-h100  --image moc-rhelai-nvidia-1.1 --network <vlan name> --candidate <node name> --ssh-public-key <path_to_key>/<key>.pub
```

### 1: Log in to your registry service account using podman
- Creating an account: `https://access.redhat.com/terms-based-registry/accounts`
- Logging in: `sudo podman login registry.redhat.io` or `sudo podman login -u='<username' - <token> registry.redhat.io `

### 2: Start a local registry
`sudo podman container run -dt -p 5000:5000 --name registry docker.io/library/registry:2`

### 3: Add the registry to `/etc/containers/registries.conf`
```
[[registry]]
location = "localhost:5000"
insecure = true
```

### 4: Reload podman
`sudo systemctl restart podman`

### 5: Build image 
`sudo podman build -t localhost:5000/moc-roce-rhelai-nvidia:1.4 .`

### 6: Push the built image to the local registry
`sudo podman push localhost:5000/moc-roce-rhelai-nvidia:1.4`

### 7 (Optional): Test the image
`sudo podman run --rm -it --device nvidia.com/gpu=all --security-opt=label=disable --entrypoint /bin/bash --privileged --network host --name node --shm-size 10.24g localhost:5000/moc-roce-rhelai-nvidia:1.4`

### 8: Switch using bootc
`sudo bootc switch localhost:5000/moc-roce-rhelai-nvidia:1.4`

### 9: Reboot
`sudo reboot`

### 10: Verify 
Check if `libibverbs-utils` has been correctly installed by running `ibv_devices` - this is needed by nccl for RoCE, else it'll try using TCP.


## To-do
- Add build recipe for iperf3, perftest (w/ cuda) and llm.c (application + virtual env)  to the Containerfile