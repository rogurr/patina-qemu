# Demonstration of Using Patina in a QEMU Platform UEFI Build

This repository demonstrates how to integrate code from the [Patina](https://github.com/OpenDevicePartnership/patina/blob/main/docs/src/patina.md)
Boot Firmware Project into a UEFI platform build.  It contains a permanent fork of [OvmfPkg in edk2](https://github.com/tianocore/edk2/tree/HEAD/OvmfPkg)
to allow maintaining the code within the ownership of the Patina project and optimizing for Rust UEFI development.  And
it is meant to be a "first stop" for developers exploring how to integrate Patina code into a UEFI platform.

The following are related links that may be useful:

- [ODP](https://opendevicepartnership.org/) - Open Device Partnership web page
- [Patina Documentation](https://opendevicepartnership.github.io/patina/) - Primary Patina documentation web page
  - [Patina Requirements](https://opendevicepartnership.github.io/patina/integrate/patina_dxe_core_requirements.html) -
  Patina requirements in comparison to EDK2.
  - [Patina Component Model](https://opendevicepartnership.github.io/patina/component/getting_started.html) - Overview
  of the component model used by Patina
- [ODP GitHub](https://github.com/OpenDevicePartnership) - Open Device Partnership GitHub page
  - [Patina Code Repository](https://github.com/OpenDevicePartnership/patina) - GitHub repository for the Patina development
  kit
  - [Sample Patina DXE Core](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) - Repository showcasing a
  sample Patina DXE core driver that loads in QEMU
  - [Sample QEMU UEFI](https://github.com/OpenDevicePartnership/patina-qemu) - Repository showcasing a sample UEFI build that
  executes in QEMU and contains the sample Patina DXE Core driver (this repo)

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

- The [Q35 Package](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/Q35/QemuQ35_ReadMe.md)
in the ```/Platforms/QemuQ35Pkg``` folder supports an Intel Q35 chipset
- The [SBSA Package](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/Platforms/Docs/SBSA/QemuSbsa_ReadMe.md)
in the ```/Platforms/QemuSbsaPkg``` folder supports an ARM Base System Architecture

Both packages can be built in either a Windows or Linux environment, but for simplicity, it is recommended to use the
[Dev Container](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/.devcontainer/devcontainer.json) that is
used by the constant integration build script.  When launched, it will provide an Ubuntu command line prompt with all of
the proper tools and environment settings necessary without making changes to the host system.

### Environment Setup

The container needs to have a Container Manager installed to handle loading and execution.  There are several managers,
but this example uses [Docker](https://docs.docker.com/) which has install instructions for [Linux](https://docs.docker.com/desktop/setup/install/linux/)
and [Windows](https://docs.docker.com/desktop/setup/install/windows-install/).

NOTE: If installing on Windows, it is best to use the WSL2 back-end instead of Hyper-V, so you will need to install
[WSL](https://learn.microsoft.com/en-us/windows/wsl/install) prior to installing Docker.  Then if prompted during
the Docker install, click the checkbox to select using the WSL2 Backend.

To confirm docker is working after installation, the version request command works in either the Windows or Linux environment.

```shell
docker --version
```

### Load and Run Container

Once Docker is installed, run the following command to download the container, install it into docker using the name 'patina-dev',
and open a command prompt inside the Ubuntu container environment.  The same run command is used in both the Linux and Windows
environment.

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

The current build script pulls a pre-compiled Patina DXE Core .efi driver from a nuget feed, the .FDF file points
to that .efi binary to add it into the final firmware device image, and the --flashrom option will launch the FW and boot
into the UEFI shell.

For other options on building and detailed notes on the environment, please refer to:

- [Advanced Compilation](https://???) page for details.
- [WinDbg + QEMU + Patina UEFI - Debugging Guide](Platforms/Docs/Common/windbg-qemu-uefi-debugging.md)
- [WinDbg + QEMU + Patina UEFI + Windows OS - Debugging Guide](Platforms/Docs/Common/windbg-qemu-windows-debugging.md)





## Advanced Usage

### Insert a new DXE Core Driver into the Build

This repository was originally created to demonstrate using Patina modules with an emphasis on ingesting the [Patina
DXE Core](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu).  To modify the build to consume a new DXE
Core binary instead of the pre-built .EFI file from the nuget feed, there are several methods supported.

#### Update the Platform FDF File

The easiest way to inject a new Patina DXE Core driver is to update the platform FDF file (`/Platforms/QemuQ35Pkg/QemuQ35Pkg.fdf`
or `/Platforms/QemuQ35Pkg/QemuQ35Pkg.fdf`) to point to the new binary driver file as typically done in UEFI builds
that ingest pre-compiled binaries.  Modify the `SECTION` definition in the `DXE_CORE` file declaration as follows:

```cmd
FILE DXE_CORE = 23C9322F-2AF2-476A-BC4C-26BC88266C71 {
  SECTION PE32 = "<new dxe core file path>"
  SECTION UI = "DxeCore"
}
```

This repository's platform FDF files support defining a build variable to override the default binary without needing
to modify the FDF file.  This can be set from the stuart_build command line by defining `BLD_*_DXE_CORE_BINARY_OVERRIDE':

```cmd
stuart_build -c Platforms\QemuQ35Pkg\PlatformBuild.py --FLASHROM BLD_*_DXE_CORE_BINARY_OVERRIDE="<new dxe core file path>"
```

#### Patching a Pre-Built UEFI Firmware Device Image

If multiple iterations of the DXE core are to be tested, the fastest way to integrate each to a bootable FD image is
using the [Patina FW Patcher](https://github.com/OpenDevicePartnership/patina-fw-patcher). This tool will open an
existing UEFI FD binary, find and replace the current DXE Core driver with a new file, and launch QEMU with the patched
ROM image.

A [build_and_run_rust_binary.py](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/build_and_run_rust_binary.py)
script is provided in the root of this repository to perform all steps necessary to compile the Patina DXE core driver,
call the patcher, and start QEMU.  For more details, run it with the `--help` command line parameter:

```cmd
python build_and_run_rust_binary.py --help
```

- Note 1: This tool is not a general FW patcher to be used on any UEFI FD image.  It relies on specific features
  implemented in this UEFI build.
- Note 2: Because this tool is patching an existing QEMU ROM image, only changes to the Rust DXE Core code will be
  merged.  Any changes to the C code will require running a full stuart_build process to build a new ROM image.
- Note 3: The tool can be enhanced to patch more than the Patina DXE Core.  If there is interest in new features,
  please start a discussion in the tool's repo [discussions](https://github.com/OpenDevicePartnership/patina-fw-patcher/discussions/categories/q-a)
  area.

### Using a Custom QEMU Installation

By default, this repository automates the process of choosing a known working QEMU version and downloading that version
into the workspace for you. If you want to use a custom QEMU installation, you can do so by passing the path to the
Stuart build command with the`QEMU_PATH` argument. For example:

```cmd
stuart_build -c Platforms/QemuQ35Pkg/PlatformBuild.py --flashonly QEMU_PATH="<path to qemu executable>"
```

You can also specify the directory where the QEMU binary is located by passing the `QEMU_DIR` argument. For example:

```cmd
stuart_build -c Platforms/QemuQ35Pkg/PlatformBuild.py --flashonly QEMU_DIR="<path to qemu bin directory>"
```

### Self Certification Tests

Refer to the [Self Certification Test](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/docs/SelfCertifcationTest.md)
documentation for information on how to configure and run the [Self Certification Tests (SCTs)](https://github.com/tianocore/tianocore.github.io/wiki/UEFI-SCT).
