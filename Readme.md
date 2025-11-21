# Demonstration of Patina in a QEMU UEFI Platform Build

This repository demonstrates how to integrate code from the Open Device Partnership Patina Boot Firmware Project into
a UEFI platform build. It contains a permanent fork of [OvmfPkg in edk2](https://github.com/tianocore/edk2/tree/HEAD/OvmfPkg)
to allow maintaining the code within the ownership of ODP and is meant to be a "first stop" for developers exploring
Patina Boot Firmware.

- [ODP](https://opendevicepartnership.org/) - Open Device Partnership documentation web page
  - [Patina Documentation](https://opendevicepartnership.github.io/patina/) - Patina Boot Firmware documentation web page
- [ODP on GitHub](https://github.com/OpenDevicePartnership) - Open Device Partnership GitHub page
  - [Patina on GitHub](https://github.com/OpenDevicePartnership/patina) - Patina Project GitHub page
  - [Patina DXE Core QEMU on GitHub](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) - Repository showcasing
 a sample Patina DXE core driver that is loaded by this repository's QEMU UEFI boot

## High-Level Overview of Rust Integration

As Rust adpotion increases, it is important to determine the best way to incorporate those changes during the transition
from C to Rust.  UEFI inherently supports dynamic integration, so at a high level there are basically 2 approaches for
writing UEFI firmware in Rust and ingesting it into the final FirmwareDevice image:

1. Build the code using Rust tools in a stand-alone workspace to produce a .efi binary, then integrate it into the firmware
device (FD) build process defined by the .fdf file.
2. Add support to the EDK2 build infrastructure to compile the Rust source code alongside the C source code when processing
each module specified in a DSC file.

This 2nd approach is a viable solution and discussed in the [Rust Integration](https://github.com/???) documentation, but
the Patina project is focused primarily on the first approach since it allows for a more natural Rust development experience
using only Rust tools and processes.  It also greatly simplifies the integration by not requiring modifications to EDK2
build scripts.

## Compiling

There are two platforms currently supported in this repository:

- The [Q35 Package](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/Q35/QemuQ35_ReadMe.md)
in the ```/Platforms/QemuQ35Pkg``` folder supports an Intel Q35 chipset
- The [SBSA Package](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/SBSA/QemuSbsa_ReadMe.md)
in the ```/Platforms/QemuSbsaPkg``` folder supports an ARM Base System Architecture

Both packages can be built in either a Windows or Linux environment, but for simplicity, it is recommended to follow the
same process as the constant integration build script and use a
[Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/.devcontainer/devcontainer.json). When
launched, it will provide an Ubuntu command line prompt with all of the proper tools and environment settings necessary
without making changes to the host system.

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

### Load and Run Container

Once Docker is installed, run the following command to download the container, and open a command prompt inside the
Ubuntu container environment.  The same run command is used in both the Linux and Windows environment.

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

Before using the command, the ```[MY_WORKSPACE_PATH]``` string needs to be updated to point to the directory that
contains the repository you plan to compile.

If running on Windows, the Windows drives can be accessed from within WSL by using the ```/mnt/c``` for the C drive, and
from Windows the WSL 'home' folders can be accessed using the ```\\wsl.localhost\Ubuntu\home``` path.  But translating
files across the file systems will add latency that can cause the build to be very slow.  So it is recommended to clone
the repository in the WSL environment and use a path that points into the linux environment when running docker.

If using a different container manager, the command line parameters were created from the data in the
[Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/refs/heads/main/.devcontainer/devcontainer.json)
JSON file that the CI build uses to execute the container.  And the name ```patina-dev``` was selcted to register the
container with Docker, so the next time you need to open the environment, a simplified form of the run command can be used:

```shell
  docker start -ai "patina-dev"
```

### Build the code

Once in the container's Ubuntu shell, the repository can be accessed by switching to the ```/workspace``` directory and Git
needs to be notified the repo is safe:

```shell
  cd /workspace
  git config --global --add safe.directory '*'
```

Since this is inside the container and will not affect the host environment, it is safe to run the compilation installing
any global pip requirements without using the python workspace.  And since the environment was specifically setup to
compile this codebase, Stuart can be run without any specific toolchain tags:

```shell
  pip install --upgrade -r pip-requirements.txt
  stuart_setup -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_update -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_build -c Platforms/QemuSbsaPkg/PlatformBuild.py --flashrom
```

The --flashrom option for stuart_build will launch the firmware which uses the Patina DXE Core dispatcher and sample rust
drivers to boot into the UEFI shell.







For other options on building and detailed notes on the environment, please refer to:

- [XXXX](https://???) - Page 1
- [XXXX](https://???) - Page 2
- [XXXX](https://???) - Page 3
