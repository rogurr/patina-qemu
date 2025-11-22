# High-Level Overview of Rust Integration

As Rust adpotion increases, it is important to determine the best way to incorporate tnew code changes into the current
infrastructure. UEFI inherently supports dynamic integration, so at a high level there are basically 2 approaches for
writing and ingesting UEFI firmware written in Rust:

1. Build the code using Rust tools in a stand-alone workspace to produce a standard .efi binary, then integrate it into
the firmware device (FD) build process.
2. Add support to the EDK2 build infrastructure to compile Rust source code alongside the C source code when processing
each module specified in a DSC file.

The second option is a viable solution and this repository has several examples, but the first option is the primary method
used to ingest the Patina DXE core since it allows for a more natural development experience using the Rust tools and
processes, and it greatly simplifies the integration.

## Integration Option 1

The preferred method to add a Rust based module into an EDK II build is to pre-compile the code to produce the module's
.efi binary then add its file path to the platform .fdf file to be integrated when creating the firmware volumes and final
firmware device file.

The [Patina DXE Core QEMU](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) repository is an example of this
process and contains code to build a fully Rust based DXE core driver targeted toward either the SBSA or Q35 platform.
Its Constant Integration GitHub action creates a stand-alone .efi DXE Core binary that is published to a nuget feed that
this repository can then use during its build.

This repo, the [Patina QEMU UEFI](https://github.com/) repository, has its own Constant Integration action to pull the
nuget feed and extract the binary.  Then when compiling, the platform .fdf file points to the Patina DXE Core .efi binary
to link it into the final firmware device file.

Both platform [QemuQ35Pkg.fdf](https://sadf) and [QemuQ35Pkg.fdf](https://sadf) files in this repository have a
```[FV.RUST_DXE_CORE]``` firmware volume definition section that contains a single driver, the Patina DXE Core QEMU .efi
binary. There are several 'if' statements to support multiple options, but the easiest method to inject a user built binary
is to update the ```FILE DXE_CORE``` section to point directly to the newly built .efi binary and re-compile.

```text
  FILE DXE_CORE = 23C9322F-2AF2-476A-BC4C-26BC88266C71 {
    SECTION PE32 = "< new dxe core file path >"
    SECTION UI = "DxeCore"
  }
```

The 'if' statements in that section allow support of defining the newly created .efi binary on the build command line.
By setting the DXE_CORE_BINARY_OVERRIDE define to the new binary's file path, it will be included without having to modify
the .fdf file.

```cmd
  stuart_build -c Platforms\QemuQ35Pkg\PlatformBuild.py --FLASHROM BLD_*_DXE_CORE_BINARY_OVERRIDE="<new dxe core file path>"
```

Or if multiple iterations of replacement and testing are needed, the Patina DXE Core binary was placed in its own firmware
volume to allow supporting the [Patina FW Patcher](https://github.com/OpenDevicePartnership/patina-fw-patcher). The
[build_and_run_rust_binary.py](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/build_and_run_rust_binary.py)
script is provided in the root of this repository to perform all steps necessary to compile the Patina DXE core driver,
call the patcher, and start QEMU.  For more details, run it with the `--help` command line parameter:

```cmd
  python build_and_run_rust_binary.py --help
```

Note that this tool is not a general FW patcher to be used on any UEFI FD image due to relying on specific features
implemented in this UEFI build.  However if there is interest in adding new features, please start a discussion in the
tool's repo [discussions](https://github.com/OpenDevicePartnership/patina-fw-patcher/discussions/categories/q-a) area.

## Integration Option 2

The [Tianocore EDK II](https://github.com/tianocore/edk2) environment does not currently support compiling Rust drivers
without the end user updating and maintianing the build rules to handle the Rust toolchain.  This coupling of the EDK II
build system with the Rust/Cargo build system introduces additional complexity that can be overcome, but proved to be
too difficult to provide a solution in a simple and concise manor in this project.

For instance trying to define a simple and straight forward approach for the Rust environment to ingest EDK II PCDs or
for the EDK II environment to control Rust features proved difficult due to the number of possible ways to handle the
task and the complexity in describing the chosen solution.  In addition, the complexity from co-integrating the Rust/Cargo
build system with the EDK II build system leads to Rust source code being maintained in the C codebase which is not
ideal due to language and tooling differences.

If an end user does wish to explore using integration option 2, there are several benefits, one of which is allowing the
transition from a C codebase to a Rust codebase in small incremental steps intead of an "all-or-nothing" approach.  Even
though it is not the recommended method, this repository does have several examples of drivers that are written in Rust
and compiled by the stuart_build process.  This doesn't provide the security benefits of a pure Rust based build, but it
does allow for interim steps:

- Modules written in Rust that link a Rust based library (aka crate)
- Modules written in Rust that link a C based library
- Modules written in C that link a Rust based library (aks crate producing cdecl apis)
- Modules written in C that link a C based library

This repository took the minimal approach to implement the dual build environment by placing a common [cargo.toml](https://sfazsddf)
file in the root that contains a ```members``` section to indicate all possible Rust modules to build, and the .inf file
lines included in the .dsc/.fdf files indicate which module to include in the platform's build.  When stuart_build is
executed, all of the Rust modules are compiled first, the C modules next, then the modules are linked into the final
FirmwareDevice image.
