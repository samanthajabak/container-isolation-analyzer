# Docker vs Kubernetes Container Isolation Comparison

This document compares container isolation behavior between Docker and Kubernetes using the same escape-oriented analysis scripts.

## Baseline Behavior
- Docker (unprivileged) and Kubernetes (safe pod) show nearly identical isolation.
- Both use overlayfs, isolate namespaces, restrict capabilities, limit devices, and block kernel logs.

## Privileged Configuration
- Docker `--privileged` and Kubernetes `securityContext.privileged: true` both:
  - Enable all Linux capabilities
  - Expand device access significantly
  - Allow kernel log access
- Kubernetes requires explicit YAML configuration, reducing accidental misuse.

## Host Filesystem Exposure
- Docker `-v /:/host` and Kubernetes `hostPath: /` both allow direct host filesystem access.
- This is dangerous even without privileged mode or extra capabilities.
- Kubernetes hostPath mounts are subtle and easy to overlook in YAML.

## Key Differences
- Docker misconfigurations are fast and CLI-driven.
- Kubernetes misconfigurations are declarative and harder to spot in reviews.
- Kubernetes defaults are safe, but mistakes scale faster.

## Final Takeaway
Docker and Kubernetes provide strong isolation by default.  
Security failures arise from explicit misconfigurations, especially privileged containers and host filesystem mounts.  
Kubernetes reduces accidental risk but increases impact when misconfigured.
