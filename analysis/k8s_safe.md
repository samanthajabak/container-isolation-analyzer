# Kubernetes Safe Baseline Analysis

This test evaluates the default isolation behavior of a Kubernetes pod with no added privileges or capabilities.  
The same analysis scripts used in the Docker baseline were executed inside the pod to ensure a fair comparison.

## Environment
- Orchestrator: Kubernetes (local cluster via kind)
- Pod type: Default, non-privileged
- Container image: unprivileged-container
- Analysis method: escape-oriented inspection scripts

---

## Observed Results

### Filesystem Isolation
- The root filesystem inside the pod is mounted as overlayfs.
- No host filesystem mounts were detected.
- This indicates that the pod is operating on an isolated container filesystem rather than the host’s root filesystem.

**Interpretation:**  
By default, Kubernetes does not expose the host filesystem to pods, matching Docker’s safe configuration.

---

### Namespace Isolation
- No host namespaces were visible during inspection.
- The pod could not observe host PID, mount, network, or other namespaces.

**Interpretation:**  
Kubernetes enforces strong namespace isolation by default, preventing pods from seeing or interacting with host processes.

---

### Linux Capabilities
- The container was granted only the default Docker capability set.
- High-risk capabilities such as `cap_sys_admin` and `cap_sys_ptrace` were explicitly absent.
- The bounding and ambient capability sets remained restricted.

**Interpretation:**  
Kubernetes does not grant elevated kernel privileges to pods unless explicitly configured, maintaining a minimal attack surface.

---

### Device Exposure
- Only basic virtual devices were accessible (e.g., `/dev/null`, `/dev/random`, `/dev/tty`).
- No sensitive or host-level devices were exposed.

**Interpretation:**  
Device access in a default Kubernetes pod is tightly restricted and comparable to a safe Docker container.

---

### Kernel Log Access
- Attempts to read kernel logs using `dmesg` failed with “Operation not permitted.”

**Interpretation:**  
Kernel logs remain protected, preventing information leakage about the host kernel.

---

## Comparison to Docker Safe Baseline

The Kubernetes safe pod exhibited nearly identical isolation behavior to the Docker unprivileged container:
- Overlay filesystem
- No host namespace visibility
- Default capability set
- Minimal device exposure
- Blocked kernel log access

---

## Key Takeaway

A default Kubernetes pod is **not inherently less secure than a default Docker container**.  
In both systems, strong isolation is maintained unless explicit misconfigurations are introduced.

This establishes a clean baseline for comparing how security posture changes under privileged or unsafe configurations in Kubernetes.
