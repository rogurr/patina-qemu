# Demonstration of Patina in a QEMU UEFI Platform Build

The purpose of this repository is to demonstrate how to integrate code from the Open Device Partnership's project
"Patina Boot Firmware" into a UEFI platform build.  It contains a permanent fork of [OvmfPkg in edk2](https://github.com/tianocore/edk2/tree/HEAD/OvmfPkg)
to allow maintaining the code within the ownership of ODP and is meant to be a "first stop" for developers exploring
ODP and the Patina Boot Firmware:

- [Open Device Partnership](https://opendevicepartnership.org/) - ODP documentation web page
- [Patina Boot Firmware](https://opendevicepartnership.github.io/patina/) - Patina documentation web page

- [ODP on GitHub](https://github.com/OpenDevicePartnership) - Open Device Partnership GitHub page
- [Patina on GitHub](https://github.com/OpenDevicePartnership/patina) - Patina Project GitHub page
- [Patina DXE Core QEMU on GitHub](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) - Repository showcasing
a sample Patina DXE core .efi binary used in this repository

## High-Level Overview

As Rust adpotion increases, it is important to determine the best way to incorporate changes during the transition away from
code written in C to code written in Rust.  UEFI inherently supports dynamic integration, so at a high level there are two
basic approaches:

1. Build the code using Rust tools in a stand-alone workspace to produce a .efi binary that is later integrated into the
FirmwareDevice (FD) image during the process of combining .efi binary modules into the firmware volumes
2. Add support to the EDK2 build infrastructure to compile the Rust source code alongside the C source code when processing
each module specified in a DSC file

This 2nd approach is a viable solution, but the Patina project is focused primarily on the first approach since it allows
for a more natural Rust development experience using only Rust tools and processes.  It also greatly simplifies the integration
by not requiring modifications to EDK2 build scripts.  Both options are discussed in the
[Rust Integration](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Rust_Integration.md) documentation

## Compiling

There are two platforms currently supported in this repository:

- [QEMU Q35](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/Q35/QemuQ35_ReadMe.md) covers
the build for an Intel Q35 chipset
- [QEMU SBSA](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/SBSA/QemuSbsa_ReadMe.md) covers
the build for an ARM System Architecture

Both packages can be built in either a Windows or Linux environment, but for simplicity, it is recommended to use a
[Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/.devcontainer/devcontainer.json).  This is
the same process used by the constant integration build script and provides an Ubuntu command line prompt with all of the
proper tools and environment settings necessary without making changes to the host system.

### Environment Setup

The container needs to have a Container Manager installed to handle loading and execution.  There are several managers,
but this example uses [Docker](https://docs.docker.com/) which has install instructions for [Linux](https://docs.docker.com/desktop/setup/install/linux/)
and [Windows](https://docs.docker.com/desktop/setup/install/windows-install/).

NOTE: If installing on Windows, it is best to use the WSL2 back-end instead of Hyper-V, so you will need to install
[WSL](https://learn.microsoft.com/en-us/windows/wsl/install) prior to installing Docker.  Then if prompted during the Docker
install, click the checkbox to select using the WSL2 Backend.

To confirm docker is working after installation, the version request command works in either the Windows or Linux environment.

```shell
docker --version
```

### Load and Run the Container

Once Docker is installed, the following command will download the container and open a command prompt inside its Ubuntu
environment.  If using a Windows device, the command should be run from within a WSL command box.

```shell
  docker run -it \
    --privileged \
    --name "patina-dev" \
    -v "[MY_WORKSPACE_PATH]:/workspace" \
    -p 5005-5008:5005-5008 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY="${DISPLAY:-:0}" \
    "ghcr.io/microsoft/mu_devops/ubuntu-24-dev:latest" \
    /bin/bash
```

And prior to executing the command, the `[MY_WORKSPACE_PATH]` string needs to be updated to point to the directory that
contains the repository you plan to compile.

If your host system is running Windows, the Windows `C:`, `D:`, etc. drives can be accessed from within WSL by using `/mnt/c`,
`/mnt/d`, etc., but the translation layer between the two file systems adds significant latency that will cause the build
to be dramatically slower.  So it is recommended to clone the repository in the same WSL environment that launches the container.

If using a different container manager than Docker, the command line parameters were created from the data in the
[Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/refs/heads/main/.devcontainer/devcontainer.json)
JSON file.

And the name `patina-dev` was selcted to register the container with Docker, so the next time you need to open the environment,
a simplified form of the run command can be used

```shell
  docker start -ai "patina-dev"
```

### Build the code

Once in the container's Ubuntu shell, the repository can be accessed by switching to the `/workspace` directory and Git
needs to be notified the repo is safe:

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

The --flashrom option for stuart_build will launch the firmware and boot into the UEFI shell.  For more options or details
about the environment, please refer to [Rust Integration](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Rust_Integration.md)
or [Build Details](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/Build_Details.md).
