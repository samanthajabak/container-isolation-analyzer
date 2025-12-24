# Container Isolation Analyzer
A hands-on security analysis project that compares container isolation behavior between Docker and Kubernetes under safe and unsafe configurations.

This project builds on a custom escape-oriented test suite to examine how container isolation changes when common misconfigurations are introduced, including privileged execution and host filesystem mounts.

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

The same escape-oriented analysis scripts are run across all scenarios to inspect:

1. **Filesystem isolation**
   - Is the host filesystem visible or mounted inside the container?
2. **Namespace isolation**
   - Can the container see host processes or namespaces?
3. **Linux capabilities**
   - Are high-risk capabilities like `cap_sys_admin` enabled?
4. **Device exposure
