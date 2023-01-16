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

variable "memory" {
  type    = string
  default = "2048M"
}

variable "disk_size" {
  type    = string
  default = "40000"
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
  workdirpacker  = "${var.build_directory}/packer-${var.os_name}-${var.release}-qemu"
}

source "qemu" "fedora-coreos" {
  accelerator = "kvm"
  boot_wait   = "45s"
  boot_command = ["curl -LO http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.ign<enter><wait>",
    "sudo coreos-installer install /dev/sda --ignition-file config.ign",
    "&& sudo reboot<enter>",
    "<wait90s>",
  ]
  disk_size        = "${var.disk_size}"
  format           = "qcow2"
  iso_checksum     = "sha256:${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  output_directory = "${local.workdirpacker}"
  qemuargs = [
    ["-smp", "${var.cpus}"],
    ["-m", "${var.memory}"]
  ]
  shutdown_command = "sudo shutdown now"
  ssh_password     = "packer"
  ssh_username     = "core"
  vm_name          = "container-linux-${var.release}.qcow2"
  http_directory   = "${local.http_directory}"
}

build {
  sources = ["source.qemu.fedora-coreos"]

  provisioner "shell" {
    environment_vars  = ["http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "sudo -E env {{ .Vars }} bash '{{ .Path }}'"
    expect_disconnect = false
    scripts           = ["${path.root}/provision/provision.sh"]
  }

  # https://developer.hashicorp.com/vagrant/docs/boxes/info
  post-processors {
    post-processor "artifice" {
      files = ["${var.build_directory}/packer-${var.os_name}-qemu/info.json"]
    }
    post-processor "shell-local" {
      inline = ["echo {\"os_name\": \"${var.os_name}\", \"release\": \"${var.release}\"} > ${local.workdirpacker}/info.json"]
    }
  }
  post-processors {
    post-processor "vagrant" {
      compression_level = 9
      include           = ["${local.workdirpacker}/info.json"]
      output            = "${var.build_directory}/${var.os_name}-${var.release}_{{.Provider}}.box"
      /* provider_override    = "virtualbox" */
      vagrantfile_template = "${path.root}/files/vagrantfile"
    }
  }
}

