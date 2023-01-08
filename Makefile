# vi: ts=4 list noexpandtab

.PHONY: default
default:
	@printf "Use:\n\n"
	@echo "make update	get latest version of CoreOS Stable"
	@echo "make ign	run butane script to update ignition file"
	@echo "make build	update ignition file and run packer build"

.PHONY: update
update:
	./update_vars.sh

.PHONY: ign
ign:
	./utils/makeign.sh

.PHONY: build
build: ign
	 packer build -var-file="stable.pkrvars.hcl" fedora-coreos.pkr.hcl

.PHONY: clean
clean:
	rm -rf builds
