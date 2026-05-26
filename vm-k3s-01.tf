# ----------------------------------------------------------------------
# k3s-01 VM — IMPERATIVE-MANAGED, NOT in tofu state.
#
# History:
#   - Originally provisioned via tofu on the RIT proxmox instance.
#   - After the RIT decommission (May 2026) the VM was rebuilt manually
#     on the home proxmox (192.168.0.100) with substantial divergences
#     from the original source:
#       * UEFI/ovmf BIOS + q35 machine type (for PCI passthrough)
#       * NVIDIA GPU passthrough on hostpci0 (0000:09:00, x-vga=1)
#       * Dual network: net0 vmbr0 (public LAN), net1 vmbr1 (cluster)
#       * Bumped to 8 cores / 14 GiB max with 12 GiB balloon floor
#       * 70 GiB scsi0 + 1 MiB efidisk0
#       * Cloud-init via ide2 + tank-vms storage
#   - On 2026-05-26 the resource was removed from tofu state because
#     reconciling source to these post-migration mutations would force
#     a destructive replace, and the bpg/proxmox provider does not
#     cleanly express GPU passthrough.
#
# If/when this VM is recreated from scratch (DR scenario), see the
# fresh-cluster bootstrap notes in homelab-finish-setup.md. The actual
# qm config is the canonical source of truth today:
#
#     ssh pve qm config 100
# ----------------------------------------------------------------------
