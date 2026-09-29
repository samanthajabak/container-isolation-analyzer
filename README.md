# Container Isolation Analyzer
A hands-on security analysis project that compares container isolation behavior between Docker and Kubernetes under safe and unsafe configurations.

This project builds on my [Cloud Container Escape Simulator](https://github.com/samanthajabak/cloud-container-escape-simulator) test suite to examine how container isolation changes when common misconfigurations are introduced, including privileged execution and host filesystem mounts.

---

## Project Motivation

Modern cloud environments rely heavily on containers and orchestration platforms like Docker and Kubernetes. While both provide strong isolation by default, real-world security incidents frequently stem from subtle configuration mistakes rather than software vulnerabilities.

This project was built to:
- Understand how container isolation works in practice
- Reproduce real-world misconfigurations in a controlled environment
- Compare Docker and Kubernetes behavior using identical analysis logic
- Demonstrate why secure defaults matter, and how isolation can silently fail

---

## What This Project Tests

The same five escape-oriented checks (`scripts/run_analysis.sh`) are run across all scenarios:

1. **Filesystem isolation**: Is the host filesystem visible or mounted inside the container?
2. **Namespace isolation**: Can the container see host processes or namespaces?
3. **Linux capabilities**: Are high-risk capabilities like `cap_sys_admin` enabled?
4. **Device exposure**: Which `/dev` entries can the container access?
5. **Kernel log access**: Can the container read host kernel logs through `dmesg`?

---

## Scenarios

Each misconfiguration was reproduced on both platforms so the results could be compared directly.

| Scenario | Docker | Kubernetes |
|---|---|---|
| Safe baseline | Default `docker run` / `docker-compose/safe.yml` | `k8s/safe-pod.yaml` |
| Privileged | `--privileged` | `securityContext.privileged: true` (`k8s/privileged-pod.yaml`) |
| Host filesystem mount | `-v /:/host` | `hostPath: /` mounted at `/host` (`k8s/hostpath-pod.yaml`) |

All Kubernetes tests ran on a local cluster created with kind, using the same `unprivileged-container` image as the Docker tests. The Docker privileged and host-mount results come from the Escape Simulator runs.

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

---

## Interpretation

**Safe baseline.** The default Kubernetes pod behaved almost exactly like the unprivileged Docker container. Both used overlayfs, kept host namespaces hidden, granted only the default capability set, exposed only basic virtual devices, and blocked kernel logs. A default pod is not inherently less secure than a default Docker container.

**Privileged.** Setting `privileged: true` in Kubernetes produced the same result as Docker's `--privileged` flag. All Linux capabilities were enabled, including `cap_sys_admin`, `cap_sys_module`, and `cap_sys_rawio`. Host-level devices became visible and kernel boot logs were readable. The filesystem and namespaces stayed isolated, but this is close to root-level power inside the container.

**Host filesystem mount.** This was the most dangerous scenario on both platforms, even though the container had no extra capabilities and was not privileged. Mounting `/` at `/host` gave direct access to host directories like `/etc`, `/bin`, `/usr`, and `/var`. Access to the host filesystem alone is enough to break the isolation model.

---

## Key Takeaways

- Docker and Kubernetes provide equally strong isolation by default. Failures come from explicit misconfigurations.
- A host filesystem mount breaks isolation without privileged mode or added capabilities, which makes it easy to underestimate.
- Kubernetes makes privileged mode explicit in YAML, which reduces accidental misuse. But `hostPath` volumes are subtle and easy to miss in code review, and a mistake in a shared manifest can spread across many pods.

---

## Limitations

- The namespace check (`lsns | grep host`) matches any `lsns` line containing the word "host," including the container's own command line. In the Docker host-mount run, the namespace IDs it printed were the container's own namespaces rather than the host's. A stricter check would compare namespace inode numbers against the host's (for example, `readlink /proc/1/ns/*` inside and outside the container).
- The device check lists only the first 20 entries of `/dev`, so it shows that device exposure expanded under privileged mode but not the total device count.
- All tests ran locally (Docker Desktop and kind), not on a managed cloud cluster.
