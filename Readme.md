# Demonstration of Using Patina in a QEMU Platform UEFI Build

This repository demonstrates how to integrate code from the [Patina](https://github.com/OpenDevicePartnership/patina/blob/main/docs/src/patina.md)
Boot Firmware Project into a UEFI platform build.  It contains a permanent fork of [OvmfPkg in edk2](https://github.com/tianocore/edk2/tree/HEAD/OvmfPkg)
to allow maintaining the code within the ownership of the Patina project and optimizing for Rust UEFI development.  And
it is meant to be a "first stop" for developers exploring how to integrate Patina code into a UEFI platform.

The following are related links that may be useful:

- [ODP](https://opendevicepartnership.org/) - Open Device Partnership web page
- [Documentation](https://opendevicepartnership.github.io/patina/) - The Patina project documentation web page
  - [Requirements](https://opendevicepartnership.github.io/patina/integrate/patina_dxe_core_requirements.html) -
  Patina requirements in comparison to EDK2.
  - [Component Model](https://opendevicepartnership.github.io/patina/component/getting_started.html) - Overview
  of the component model abstraction used by Patina
- [ODP GitHub](https://github.com/OpenDevicePartnership) - Open Device Partnership GitHub page
  - [Patina GitHub](https://github.com/OpenDevicePartnership/patina) - GitHub repository for the Patina Firmware code
  - [Patina DXE Core QEMU GitHub](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) - Repository showcasing a
  sample Patina DXE core driver that loads in QEMU
  - [Patina QEMU UEFI GitHub](https://github.com/OpenDevicePartnership/patina-qemu) - This repository showcases a sample
  UEFI build that executes in QEMU and launches the sample Patina DXE Core driver

## High-Level Overview of Rust Integration

As Rust adpotion increases, it is important to determine the best way to incorporate those changes into current infrastructure
during the transition from C to Rust.  UEFI inherently supports dynamic integration, so at a high level there are basically
2 approaches for writing UEFI firmware in Rust:

1. Build the code using Rust tools in a stand-alone workspace to produce a standard .efi binary, then integrate it into
the firmware device (FD) build process.
2. Add support to the EDK2 build infrastructure to compile Rust source code alongside the C source code when processing
each module specified in a DSC file.

This 2nd approach is a viable solution and discussed in the [Compiling in EDK2 Build](https://github.com/???)
documentation, but this repository takes the first approach since it allows for a more natural Rust development
experience using only Rust tools and processes.  It also greatly simplifies the integration by not requiring
modifications to EDK2 build scripts.

## Compiling

There are two platforms currently supported in this repository:

- [QemuQ35Pkg](https://github.com/OpenDevicePartnership/patina-qemu/tree/main/Platforms/QemuQ35Pkg)
  - Intel Q35 chipset with ICH9 south bridge and AMD Cpu
  - This package demonstrates [x86/x64 UEFI firmware development](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/Q35/QemuQ35_ReadMe.md)
  using Patina

- [QemuSbsaPkg](https://github.com/OpenDevicePartnership/patina-qemu/tree/main/Platforms/QemuSbsaPkg)
  - ARM Server Base System Architecture
  - This package demonstrates [AARCH64 UEFI firmware development](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/SBSA/QemuSbsa_ReadMe.md)
  using Patina

Both packages can be built in either a Windows or Linux environment, but for simplicity, it is recommended to use the
Container that is used by the constant integration build scripts in this repository.  The containers provide an Ubuntu
command line prompt with all of the proper tools and environment setup with minimal changes necessary to the host system.

### Environment Setup

The container needs to have a Desktop manager installed to handle loading and execution.  There are several managers, but
this example uses [Docker](https://docs.docker.com/) which has specific install instructions for [Linux](https://docs.docker.com/desktop/setup/install/linux/)
and [Windows](https://docs.docker.com/desktop/setup/install/windows-install/).

NOTE: If installing on Windows, it is best to use the WSL2 back-end instead of Hyper-V, so you will need to install
[WSL](https://learn.microsoft.com/en-us/windows/wsl/install) prior to installing Docker.  Then if prompted during
the Docker install, click the checkbox to select using the WSL2 Backend.

Once Docker is installed, it can be confirmed working by running the version request.  The command will work in either the
Windows or Linux environment:

```shell
docker --version
```

### Load and Run Container

Once Docker is installed, run the following command to download the container, install it into docker using the name 'patina-dev',
and open a command prompt inside the Ubuntu container environment.  The same run command is used in both the Linux and Windows
environment.

```text
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

NOTE 1: The ```[MY_WORKSPACE_PATH]``` string needs to be updated to point to the directory that contains the repository you
plan to compile. And the other command line parameters were created from the data in the 
[devcontainer json file](https://github.com/OpenDevicePartnership/patina-qemu/blob/refs/heads/main/.devcontainer/devcontainer.json)
that the CI build uses to execute the container.

NOTE 2: If running on Windows, it is best to clone the repository inside WSL prior to launching the container.  From inside WSL,
the Windows drives can be accessed using the path ```/mnt/c``` for the C drive, ```/mnt/d``` for the D drive, etc.  And from
Windows, the WSL 'home' folders can be accessed using the ```\\wsl.localhost\Ubuntu\home``` path, but since the container
uses the WSL back-end and translating files across the file system adds overhead, the compile can be extremely slow if code
is cloned to a Windows drive and accessed using the '/mnt' path.

### Build the code

Once in the container's Ubuntu shell, the repository can be accessed by switching to the ```/workspace``` directory and Git
needs to be notified the repo is safe:

```shell
  cd /workspace
  git config --global --add safe.directory '*'
```

Since this is inside the container and will not affect the host environment, it is safe to install any pip requirements
without using the python workspace.  And since the environment was specifically setup to compile this codebase, Stuart
can be run without any specific toolchain tags

```shell
  pip install --upgrade -r pip-requirements.txt
  stuart_setup -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_update -c Platforms/QemuSbsaPkg/PlatformBuild.py
  stuart_build -c Platforms/QemuSbsaPkg/PlatformBuild.py --flashrom
```

The sample Patina DXE Core driver is included in the final .FD file by having the script pull the pre-compiled binary from
a nuget feed and the .FDF file pointing to the .efi file.  The --flashrom option for stuart_build will launch the FW and
use the Patina DXE Core driver dispatcher to boot into the UEFI shell.

For other options on building and detailed notes on the environment, please refer to:

- [XXXX](https://???) - Page 1
- [XXXX](https://???) - Page 2
- [XXXX](https://???) - Page 3
