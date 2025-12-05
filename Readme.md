# Demonstration of Patina in a QEMU UEFI Platform Build

The primary purpose of this repository is to demonstrate integrating code from the Open Device Partnership's "Patina Boot
Firmware" project into a UEFI platform build and is meant to be a "first stop" for developers exploring ODP and the Patina
Boot Firmware. It contains a permanent fork of [OvmfPkg](https://github.com/tianocore/edk2/tree/HEAD/OvmfPkg) from EDK II
with changes based on the following:

- Documentation
  - [Open Device Partnership](https://opendevicepartnership.org/) - Primary ODP documentation web page
  - [Patina Boot Firmware](https://opendevicepartnership.github.io/patina/) - Primary documentation web page
- GitHub Links
  - [ODP](https://github.com/OpenDevicePartnership) - Open Device Partnership GitHub page
  - [Patina](https://github.com/OpenDevicePartnership/patina) - Patina Project GitHub page
  - [Patina DXE Core QEMU](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) - Repository showcasing the sample
Patina DXE core .efi binary used by this repository

## High-Level Overview

As Rust adpotion increases, it is important for each user to determine best way to incorporate changes during the transition
away from code written in C toward code written in Rust.  UEFI inherently supports dynamic integration, so at a high level 
there are two basic approaches:

1. Build the code using Rust tools in a stand-alone workspace to produce a .efi binary that is later integrated into the
FirmwareDevice (FD) image
2. Add support to the EDK2 build infrastructure to compile the Rust source code alongside the C source code when processing
each module specified in a DSC file

This 2nd approach is a viable solution, but the Patina project and the following documentation are focused primarily on the
first approach since it allows for a more natural Rust development experience using only Rust tools and processes, and also
greatly simplifies the integration by not requiring modifications to EDK2 build scripts.  However, both options are discussed
in the [Rust Integration](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Rust_Integration.md) documentation
to help each end-user determine what best fits their usage model.

## Compiling this Repository

There are two platform projects currently supported in this repository:

- [QEMU Q35](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/Q35/QemuQ35_ReadMe.md) supports
an Intel Q35 chipset
- [QEMU SBSA](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/SBSA/QemuSbsa_ReadMe.md) supports
an ARM System Architecture

Both packages can be built in either a Windows or Linux environment as outlined in the
[Build Details](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Build_Details.md) document.  But for
simplicity, it is recommended to start by using the environment in the [Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/.devcontainer/devcontainer.json)
used by this repository's CI build since it provides an Ubuntu command line prompt with all of the proper tools and environment
settings necessary with minimal changes to the development platform.

### Install Docker

The development platform does need to have a Container Manager installed to handle loading and execution of the container.
There are several managers available, and for this example [Docker](https://docs.docker.com/) will be used which has install
instructions for [Linux](https://docs.docker.com/desktop/setup/install/linux/) and [Windows](https://docs.docker.com/desktop/setup/install/windows-install/).

If installing on Windows, it is best to use the WSL2 (Windows Subsystem for Linux v2) back-end instead of Hyper-V, so installation
of [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) should be done prior to installing Docker.  Then if prompted
during the Docker install, click the checkbox to select using the WSL2 Backend.

To confirm docker is working after installation, execute a version request from the command line.

```shell
docker --version
```

### Load and Run the Container

Once Docker is installed, the following command will download the container, launch the container's Ubuntu environment,
and open a command prompt for use.  If using a Windows device, the command should be run from within a WSL2 command box.

```shell
  docker run -it \
    --privileged \
    -v "[MY_WORKSPACE_PATH]:/workspace" \
    -p 5005-5008:5005-5008 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY="${DISPLAY:-:0}" \
    "ghcr.io/microsoft/mu_devops/ubuntu-24-dev:latest" \
    /bin/bash
```

Note that the above command must have `[MY_WORKSPACE_PATH]` updated to the full path of the directory where this repository
was cloned. For example `-v "/home/<my_user_name>/patina-qemu:/workspace"`.

If your host system is running Windows, the Windows `C:\, D:\, etc.` drives can be accessed from within WSL2 by using
`/mnt/c/, /mnt/d/, etc.`, but the translation layer between the two file systems adds latency that will make the build
significantly slower.  It is recommended to clone the repository in the same WSL2 environment that launches the container.

And if using a different container manager than Docker, the command line parameters were created using the data in the
[devcontainer.json](https://github.com/OpenDevicePartnership/patina-qemu/blob/refs/heads/main/.devcontainer/devcontainer.json)
file.

### Build the code

Once at the container's Ubuntu command prompt, the repository can be accessed by switching to the `/workspace` directory
and Git needs to be notified the repo is safe:

```shell
  cd /workspace
  git config --global --add safe.directory '*'
```

Since this is inside the container and will not affect the host environment, it is safe to install any global pip requirements
without using the python workspace.  And since the environment was specifically setup to compile this codebase, Stuart
can be run without any specific toolchain tags:

```shell
  pip install --upgrade -r pip-requirements.txt
  stuart_setup -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_update -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_build -c Platforms/QemuSbsaPkg/PlatformBuild.py --flashrom
```

The --flashrom option for stuart_build will launch the firmware and boot into the UEFI shell demonstrating the loading of
the pre-built Patina DXE Core driver.  For more options or details about the environment, please refer to
[Rust Integration](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Rust_Integration.md)
or [Build Details](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Build_Details.md).
