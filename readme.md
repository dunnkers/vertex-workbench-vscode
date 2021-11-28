# OpenVSCode on Vertex Workbench

Custom VM image for Vertex AI Workbench that includes OpenVSCode-server, Docker, Pyenv and Poetry.

## Features

* OpenVSCode-server as a web-based IDE for code + notebooks.
* Pyenv + Poetry for managing Python packages and environments.
* Docker for building/running docker images.
* Automatic GCS bucket mounts with rclone (which you can specify by setting the `rclone-mount-buckets` metadata attribute on the VM to a comma-delimited list of bucket names)

## Usage

To use this image, create a Vertex Workbench instance with the following VM image settings:

```
image_project  = "playground-jdruiter-257009"
image_family   = "vertex-ubuntu-vscode"
```

Once the instance has been created, you should be able to open the VSCode web UI using the `Open JupyterLab` button in the Vertex Workbench console.

## To do
- Add support for custom startup script
- Set up shutdown script for clearing metadata

## References
- https://cloud.google.com/build/docs/building/build-vm-images-with-packer#json
