PROJECT_ID ?= playground-jdruiter-257009

.PHONY: build
build:
	packer build --var project_id=${PROJECT_ID} --force packer.json
