# Container Isolation Analyzer
A hands-on security analysis project that compares container isolation behavior between Docker and Kubernetes under safe and unsafe configurations.

This project builds on my [Cloud Container Escape Simulator](https://github.com/samanthajabak/cloud-container-escape-simulator) test suite to examine how container isolation changes when common misconfigurations are introduced, including privileged execution and host filesystem mounts.

---


## What This Project Tests

The same five escape-oriented checks (`scripts/run_analysis.sh`) are run across all scenarios:

1. **Filesystem isolation**: Is the host filesystem visible or mounted inside the container?
2. **Namespace isolation**: Can the container see host processes or namespaces?
3. **Linux capabilities**: Are high-risk capabilities like `cap_sys_admin` enabled?
4. **Device exposure**: Which `/dev` entries can the container access?
5. **Kernel log access**: Can the container read host kernel logs through `dmesg`?

---


## How to Run

Build the `unprivileged-container` image from the Escape Simulator repo first. Then, from the root of this repo:

```bash
# Docker safe baseline
docker compose -f docker-compose/safe.yml up

# Kubernetes (local kind cluster)
kind create cluster --name isolation-lab
kind load docker-image unprivileged-container:latest --name isolation-lab
for pod in safe privileged hostpath; do
  kubectl apply -f k8s/${pod}-pod.yaml
  kubectl wait --for=condition=Ready pod/${pod}-pod --timeout=60s
  kubectl cp scripts ${pod}-pod:/scripts
  kubectl exec ${pod}-pod -- bash /scripts/run_analysis.sh > analysis/raw_${pod}.txt 2>&1
done

# Clean up
kind delete cluster --name isolation-lab
```

The privileged and hostPath pods are intentionally unsafe. Run them only in a disposable local cluster.

---

## Results Summary

| Scenario | Platform | Root FS | Host namespaces visible? | Capabilities | Devices | Kernel logs (`dmesg`) | Host FS access |
|---|---|---|---|---|---|---|---|
| Safe baseline | Docker | overlayfs | No | Default set (14) | Minimal | Blocked | No |
| Safe baseline | Kubernetes | overlayfs | No | Default set (14) | Minimal | Blocked | No |
| Privileged | Docker | overlayfs | No | Full set (`=ep`) | Expanded | Allowed | No |
| Privileged | Kubernetes | overlayfs | No | Full set (`=ep`) | Expanded (`/dev/fuse`, `gpiochip0`, `hvc*`) | Allowed | No |
| Host mount | Docker | overlayfs | See limitations | Default set (14) | Minimal | Blocked | **Yes** (`/host`) |
| Host mount | Kubernetes | overlayfs | No | Default set (14) | Minimal | Blocked | **Yes** (`/host`) |

Detailed write-ups for each Kubernetes scenario, the Docker baseline, and the side-by-side comparison are in the [`analysis/`](analysis/) folder.
