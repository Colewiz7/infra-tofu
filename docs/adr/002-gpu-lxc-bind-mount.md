# ADR-002: GPU Workloads Run In LXC With Bind-Mounted Devices, Not VFIO Passthrough To A VM

## Status
Accepted

## Context
The server has an RTX 2070 Super (Turing architecture, 8GB VRAM, fully supported by current NVIDIA mainline drivers). Three options exist for using the GPU under Proxmox: (a) VFIO passthrough to a VM, (b) bind-mount device nodes into an LXC, (c) install drivers on the host and run workloads directly on Proxmox.

## Decision
Run a privileged LXC container (`vmid 200`) with the host's NVIDIA device nodes (`/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`, `/dev/nvidia-uvm-tools`, `/dev/nvidia-modeset`) bind-mounted in. Install only the userspace NVIDIA libraries inside the LXC; the kernel module lives on the Proxmox host. Run Ollama inside this LXC via Docker with `--gpus=all`.

## Consequences
- ✅ Near-bare-metal GPU performance (no virtualization overhead, no IOMMU complexity).
- ✅ No VFIO complexity, no console-loss problem on a single-GPU host.
- ✅ The Turing generation is fully supported by NVIDIA's current driver, so no legacy branch pinning is required. Standard `apt upgrade` cycles are safe.
- ✅ 8GB VRAM is enough headroom for quantized 8B-parameter LLMs (Llama 3.1 8B Q4, Mistral 7B Q5) plus occasional Jellyfin NVENC concurrent with idle Ollama.
- ✅ Turing's NVENC supports H.264 + HEVC plus AV1 decode, useful for Jellyfin transcoding.
- ⚠️ Privileged LXC has weaker isolation than a VM. Acceptable for a single-tenant homelab.
- ⚠️ GPU bind-mount config is not in any Terraform provider. Implemented via `local-exec` provisioner editing `/etc/pve/lxc/200.conf`. Documented because interviewers will ask.
- ⚠️ Single GPU is shared between Ollama (LXC) and any future Jellyfin transcoding (k3s VM, if I ever wire it up). The NVIDIA device-plugin time-slicing pattern would solve this in-cluster, but cross-LXC/VM sharing requires either picking one or running both via the host's container runtime.

## Alternatives considered
- **VFIO passthrough to k3s VM**: complex, requires single-GPU host workarounds, loses host display console. Real benefit is multi-tenant GPU isolation, which I don't need on a single-tenant box.
- **Direct on Proxmox host**: works but mixes hypervisor and workload responsibilities. Bad blast radius. Also loses any cgroup-style resource limits.
- **Pass through to k3s VM, run NVIDIA device plugin with time-slicing**: cleaner story for a multi-GPU-workload future, but VFIO + Turing/Turing reset semantics on a single GPU make this fragile. Reconsider when adding a second GPU.

## References
- [NVIDIA Turing architecture support matrix](https://docs.nvidia.com/datacenter/tesla/drivers/index.html)
- [Proxmox LXC GPU passthrough community guide](https://forum.proxmox.com/threads/lxc-with-nvidia-gpu.146232/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/)
