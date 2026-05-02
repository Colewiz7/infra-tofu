# k3s-01: single-node k3s cluster host
# Cloud-init Debian 13, qemu-guest-agent enabled, ssh key injected.

resource "proxmox_virtual_environment_download_file" "debian_13_cloud" {
  content_type = "import"
  datastore_id = "tank-iso"
  node_name    = var.proxmox_node_name

  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name = "debian-13-genericcloud-amd64.qcow2"

  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "k3s_01" {
  name        = "k3s-01"
  description = "k3s control-plane and worker (single-node cluster)"
  tags        = ["k8s", "k3s", "managed-by-tofu"]
  vm_id       = 100

  node_name = var.proxmox_node_name

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 12288  # 12 GB
  }

  disk {
    datastore_id = "tank-vms"
    file_id      = proxmox_virtual_environment_download_file.debian_13_cloud.id
    interface    = "scsi0"
    size         = 60
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  initialization {
    datastore_id = "tank-vms"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.vm_default_user
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  scsi_hardware = "virtio-scsi-single"

  on_boot = true

  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].password,
    ]
  }
}

output "k3s_01_ipv4" {
  description = "k3s-01 IPv4 (populated after first boot via qemu-guest-agent)"
  value       = try(proxmox_virtual_environment_vm.k3s_01.ipv4_addresses[1][0], "pending guest agent")
}

output "k3s_01_id" {
  value = proxmox_virtual_environment_vm.k3s_01.id
}
