variable "iso_url" {
  type        = string
  description = "The URL of the Fedora CoreOS stable ISO image."

  validation {
    condition     = can(regex("^https://builds.coreos.fedoraproject.org.*.x86_64.iso", var.iso_url))
    error_message = "The iso_url value must be a x86_64 Fedora CoreOS ISO URL."
  }
}

variable "iso_checksum" {
  type        = string
  description = "The checksum of the Fedora CoreOS stable ISO image."

  validation {
    condition     = length(var.iso_checksum) == 64
    error_message = "The iso_checksum value must be a checksum of the Fedora CoreOS stable ISO image."
  }
}

variable "release" {
  type        = string
  description = "The Fedora CoreOS release number."
}

variable "os_name" {
  type        = string
  description = "The Fedora CoreOS OS name."
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type = string
  # Packer default is 40G
  default = "40G"
}

variable "headless" {
  type    = bool
  default = false
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "memory" {
  type = string
  # Packer default is 512M
  default = "2048"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "build_directory" {
  type    = string
  default = "builds"
}

locals {
  http_directory = "${path.root}/http"
  workdirpacker  = "${var.build_directory}/packer-${var.os_name}-${var.release}"
}

source "virtualbox-iso" "fcos" {
  # https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
  boot_command = [
    "sudo coreos-installer install /dev/sda --insecure-ignition --ignition-url http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.ign",
    " && sudo reboot<enter>",
    "<wait90s>"
  ]
  boot_wait               = "45s"
  cpus                    = "${var.cpus}"
  disk_size               = "${var.disk_size}"
  export_opts             = ["--manifest", "--vsys", "0", "--description", "${var.os_name} ${var.release}", "--version", "${var.release}"]
  guest_additions_mode    = "disable"
  guest_os_type           = "Linux_64"
  hard_drive_interface    = "sata"
  headless                = "${var.headless}"
  http_directory          = "${local.http_directory}"
  iso_checksum            = "sha256:${var.iso_checksum}"
  iso_url                 = "${var.iso_url}"
  keep_registered         = false
  memory                  = "${var.memory}"
  output_directory        = "${local.workdirpacker}-virtualbox"
  shutdown_command        = "sudo poweroff"
  ssh_port                = 22
  ssh_private_key_file    = "${path.root}/files/vagrant-id_rsa"
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  virtualbox_version_file = ""
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--vram", "9"],
    ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"]
  ]
}

source "qemu" "fcos" {
  # https://developer.hashicorp.com/packer/plugins/builders/qemu
  accelerator = "kvm"
  headless    = "${var.headless}"
  memory      = "${var.memory}"
  boot_wait   = "60s"
  boot_command = [
    "sudo coreos-installer install /dev/vda --insecure-ignition --ignition-url http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.ign",
    " && sudo reboot<enter>",
    "<wait90s>",
  ]
  disk_size        = "${var.disk_size}"
  format           = "qcow2"
  iso_checksum     = "sha256:${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  output_directory = "${local.workdirpacker}-qemu"
  qemuargs = [
    ["-smp", "${var.cpus}"],
  ]
  shutdown_command     = "sudo poweroff"
  ssh_username         = "vagrant"
  ssh_private_key_file = "${path.root}/files/vagrant-id_rsa"
  /* ssh_timeout          = "10000s" */
  /* vm_name        = "container-linux-${var.release}.qcow2" */
  http_directory = "${local.http_directory}"
}

build {
# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/build
  sources = [
    "source.virtualbox-iso.fcos",
    "source.qemu.fcos"
  ]

  provisioner "shell" {
  # https://developer.hashicorp.com/packer/docs/provisioners
  # Use Ignition for this, not this.
    environment_vars  = ["http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "sudo -E env {{ .Vars }} bash '{{ .Path }}'"
    expect_disconnect = false
    scripts           = ["${path.root}/provision/provision.sh"]
  }

  post-processors {
  # https://developer.hashicorp.com/packer/docs/post-processors

    post-processor "artifice" {
    # https://developer.hashicorp.com/vagrant/docs/boxes/info
      /* files = ["${var.build_directory}/packer-${var.os_name}-{{.Provider}}/info.json"] */
      files = ["${output_directory}/info.json"]
    }

    post-processor "shell-local" {
      inline = [
        "echo \"{\n\"os_name\": \"${var.os_name}\", \"release\": \"${var.release}\" } > ${output_directory}/info.json"
      ]
    }
  } // post-processors

  post-processors {
    post-processor "vagrant" {
      # https://developer.hashicorp.com/packer/plugins/post-processors/vagrant/vagrant
      /* compression_level    = 9 */
      include              = ["${var.build_directory}/info.json"]
      output               = "${var.build_directory}/${var.os_name}-${var.release}_{{.Provider}}.box"
      # https://developer.hashicorp.com/packer/plugins/post-processors/vagrant/vagrant#artifice
      provider_override    = "virtualbox"
      vagrantfile_template = "${path.root}/files/vagrantfile"
    }

  } // post-processors

} // build
