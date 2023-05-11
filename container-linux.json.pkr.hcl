
variable "boot_wait" {
  type    = string
  default = "45s"
}

variable "disk_size" {
  type    = string
  default = "40000"
}

variable "ignition" {
  type    = string
  default = "ignition.json"
}

variable "iso_checksum" {
  type    = string
  default = ""
}

variable "iso_checksum_type" {
  type    = string
  default = "none"
}

variable "memory" {
  type    = string
  default = "2048M"
}

variable "release" {
  type    = string
  default = "stable"
}

source "qemu" "fedora-coreos" {
  accelerator       = "kvm"
  boot_command      = ["sudo passwd core<enter><wait>", "packer<enter>", "packer<enter>", "sudo systemctl start sshd.service<enter>"]
  boot_wait         = "${var.boot_wait}"
  disk_size         = "${var.disk_size}"
  format            = "qcow2"
  iso_checksum      = "${var.iso_checksum}"
  iso_checksum_type = "${var.iso_checksum_type}"
  iso_url           = "https://${var.release}.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso"
  output_directory  = "builds"
  qemuargs          = [["-m", "${var.memory}"]]
  shutdown_command  = "sudo shutdown now"
  ssh_password      = "packer"
  ssh_username      = "core"
  vm_name           = "container-linux-${var.release}.qcow2"
}

build {
  sources = ["source.qemu.fedora-coreos"]

  provisioner "file" {
    destination = "/tmp/ignition.json"
    source      = "${var.ignition}"
  }

  provisioner "shell" {
    inline = ["sudo coreos-install -d /dev/vda -C ${var.release} -i /tmp/ignition.json"]
  }

}
