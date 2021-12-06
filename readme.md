# OpenVSCode on Vertex Workbench

Custom VM image for Vertex AI Workbench that includes OpenVSCode-server, Docker, Pyenv and Poetry.

## Features

* Ubuntu-based image
* Vertex Workbench integration for registing on the proxy, mounting data disks, etc.
* Custom components including OpenVSCode as IDE, Pyenv + Poetry for managing Python projects
* Docker for building/running docker images
* Automatic GCS bucket mounts with rclone

## Structure

The image is built using the following layers:

* 00-docker - Installs and configures docker.
* 01-workbench-bootstrap - Installs bootstrap scripts + systemd service that configures the VM for Vertex Workbench on boot. Includes steps such as mounting the (optional) data disk, registering with the Workbench proxy, etc.
* 10-openvscode-server - Installs and configures OpenVSCode-server
* 11-pyenv - Installs and configures pyenv.
* 12-poetry - Installs and configures poetry.
* 13-rclone-mount - Installs rclone + systemd service that auto-mounts buckets specified by the `rclone-mount-buckets` metadata attributes on boot.
* 20-user-bootstrap - Installs bootstrap-scripts + systemd service that configure the users home directory on boot. Is used to configure environment settings, user-managed software etc. that can't be built into the image as we want this to be stored on the data disk (which is mounted on boot).

Each of the steps are run in order by `bootstrap.sh` when building the image.

## Usage

To use this image, create a Vertex Workbench instance with the following VM image settings:

```
image_project  = "playground-jdruiter-257009"
image_family   = "vertex-ubuntu-vscode"
```

Once the instance has been created, you should be able to open the VSCode web UI using the `Open JupyterLab` button in the Vertex Workbench console.

Note that the service account used by the VM needs to have sufficient user permissions (e.g. `compute.instanceAdmin`) to set metadata on the VM, otherwise the VM will fail to register successfully with the Workbench proxy.

## To do

Vertex support:
- Add support for Vertex's custom bootstrap script
- Set up shutdown script for clearing metadata

## References
- https://cloud.google.com/build/docs/building/build-vm-images-with-packer#json
