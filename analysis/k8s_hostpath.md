# Kubernetes HostPath Mount Analysis

This test evaluates a Kubernetes pod configured with a `hostPath` volume that mounts the host root filesystem (`/`) into the container at `/host`.

Unlike privileged pods, this configuration does not grant elevated Linux capabilities, but it directly exposes the host filesystem to the container.

---

## Observed Results

### Filesystem Isolation
- The container root filesystem (`/`) remained mounted as overlayfs.
- The host filesystem was mounted separately at `/host`.

**Interpretation:**  
The container’s primary filesystem appears isolated, but a direct view into the host filesystem is available through the mounted `/host` directory.

---

### Namespace Isolation
- Host namespaces were not visible.
- Process, mount, and network namespaces remained isolated.

**Interpretation:**  
HostPath mounts do not break namespace isolation by themselves.

---

### Linux Capabilities
- The container retained only the default Docker capability set.
- High-risk capabilities such as `cap_sys_admin` were not present.

**Interpretation:**  
HostPath mounts do not require elevated kernel privileges to be dangerous.

---

### Device Exposure
- Device access remained minimal and unchanged from the safe baseline.

---

### Kernel Log Access
- Kernel logs were not accessible (`dmesg` returned “Operation not permitted”).

---

### Host Filesystem Access
- The host root filesystem was directly accessible at `/host`.
- Listing `/host` revealed standard host directories such as `/etc`, `/bin`, `/usr`, and `/var`.

**Interpretation:**  
This represents a direct container escape vector, allowing interaction with host configuration files and binaries without privileged mode.

---

## Key Takeaway

Mounting the host filesystem using a Kubernetes `hostPath` volume is one of the most dangerous container misconfigurations.

Even without elevated capabilities or privileged mode, direct access to the host filesystem breaks the isolation model and can lead to full host compromise.
