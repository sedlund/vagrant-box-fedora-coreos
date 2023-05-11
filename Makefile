# vi: tabstop=4 list noexpandtab

.PHONY: default
default:
	@printf "Use:\n\n"
	@echo "make update	get latest version of CoreOS Stable"
	@echo "make ign	run butane to update ignition file"
	@echo "make build-vbox	update ignition file and run packer virtualbox build"
	@echo "make build-qemu	update ignition file and run packer qemu build"
	@echo "make clean	remove the builds output directory"

.PHONY: update
update:
	./update_vars.sh

.PHONY: ign
ign:
	./utils/makeign.sh

.PHONY: build-vbox
build: ign
	 packer build -var-file="stable.pkrvars.hcl" -only virtualbox-iso.fcos fedora-coreos.pkr.hcl

.PHONY: build-qemu
build-qemu: ign
	 packer build -var-file="stable.pkrvars.hcl" -only qemu.fcos fedora-coreos.pkr.hcl

.PHONY: clean
clean:
	rm -rf builds/*
