# ADR-001: Proxmox VE Hypervisor Over Bare-Metal Linux

## Status
Accepted

## Context
The server is a single bare-metal box with a GTX 1060 and modest CPU/RAM. The choice was between (a) installing Debian directly and running k3s + everything else as containers, (b) installing Proxmox VE and running k3s in a VM, or (c) installing Talos Linux as a Kubernetes-native OS.

## Decision
Run Proxmox VE 9.1 as the hypervisor. Host k3s in a VM. Host Ollama and AMP in LXC containers.

## Consequences
- ✅ "Hypervisor experience" becomes a real interview answer rather than a fudge.
- ✅ Block-level VM snapshots provide a recovery path independent of Velero.
- ✅ The DR drill is demoable: VM 102 is a stopped target that boots in under a minute.
- ✅ Workloads that fight the Kubernetes model (AMP, GPU-direct Ollama) get clean LXC isolation.
- ⚠️ Adds a layer of complexity. The k3s VM has overhead vs bare metal (~5-10% in CPU and memory).
- ⚠️ NVIDIA Pascal driver must be pinned on the host; LXC bind-mounts share the host driver, so a host upgrade gone wrong takes down GPU workloads.

## Alternatives considered
- **Bare-metal Debian + k3s**: simpler, less overhead, but no real hypervisor story for the resume and no clean place to put non-k8s workloads.
- **Talos Linux**: beautiful immutable OS, but Pascal compatibility requires custom Image Factory schematics that may not be maintained indefinitely. Wrong moment for this hardware.

## References
- [Proxmox VE 9.1 release notes](https://pve.proxmox.com/wiki/Roadmap)
- [Proxmox PCI passthrough wiki](https://pve.proxmox.com/wiki/PCI(e)_Passthrough)
