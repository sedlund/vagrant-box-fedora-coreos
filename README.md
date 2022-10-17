# vagrant-box-fedora-coreos

A project for building [Fedora CoreOS](https://getfedora.org/en/coreos?stream=stable) boxes for Vagrant.

Based upon the work from https://github.com/mihailutasu/vagrant-fedora-coreos

## Requirements
- [Packer](https://www.packer.io/)
- [VirtualBox](https://www.virtualbox.org)
- [Podman](https://podman.io/) or [Docker](https://www.docker.com/) (or FCCT installed) - to generate your own Ignition files
- [jq](https://stedolan.github.io/jq/) - if you want to download the latest images of CoreOS
## Config

In `config.ign.yml` you'll find a [YAML-formatted Butane config](https://docs.fedoraproject.org/en-US/fedora-coreos/producing-ign/).
It must [conform to the Spec](https://coreos.github.io/butane/specs/).
The password generated for the config is `vagrant` which was generated by [coreos mkpasswd](https://docs.fedoraproject.org/en-US/fedora-coreos/authentication/#_using_password_authentication).

If you update it you can generate the `transpiled_config.ign`:

```shell
./util/makeign.sh
```

This outputs the Ignition config used in the install. It will be used by packer to perform the [coreos-installer pxe ignition wrap](https://coreos.github.io/coreos-installer/cmd/pxe/#coreos-installer-pxe-ignition-wrap).

### Latest version of CoreOS

You might also want to update `stable.pkrvars.hcl` file first, to the latest versions:

```shell
./update_vars.sh
```

## Secrets to upload to Vagrant Cloud

Your access token is needed for the Vagrant Cloud API. This can be generated on your [tokens page](https://app.vagrantup.com/settings/security). Populate a `secrets.pkrvars.hcl`:

```shell
cat << EOF > ./secrets.pkrvars.hcl
cloud_token = "abc123.atlasv1.xyzabc"
EOF
```

## Usage

To build a box, you need to

 - Make sure the box is created https://app.vagrantup.com/gigaohm/boxes/fedora-coreos
 - Pick your [next version](https://guides.rubygems.org/patterns/#semantic-versioning), e.g. `1.0.0`
 - Run packer with your local variable for the version number:

```shell
packer build \
  -var "box_version=1.0.0" \
  -var-file="secrets.pkrvars.hcl" \
  -var-file="stable.pkrvars.hcl" \
  fedora-coreos.pkr.hcl
```

This will download the ISO image (if not already in packer's cache) and will build the box.

### Using pre-built boxes
You can also add the pre-built boxes in Vagrant:

```shell
vagrant box add gigaohm/fedora-coreos
```

## License

```text
Copyright 2022, Gigaohm LLC
Copyright 2020, Mihai Lutasu
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
