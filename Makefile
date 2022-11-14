check-env:
ifndef PROJECT_ID
	$(error PROJECT_ID is undefined)
endif

.PHONY: build
build:
	packer build --var project_id=${PROJECT_ID} --force packer.json
