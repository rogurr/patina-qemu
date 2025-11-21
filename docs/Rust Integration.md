# High-Level Overview of Rust Integration

As Rust adpotion increases, it is important to determine the best way to incorporate tnew code changes into the current
infrastructure. UEFI inherently supports dynamic integration, so at a high level there are basically 2 approaches for
writing and ingesting UEFI firmware written in Rust:

1. Build the code using Rust tools in a stand-alone workspace to produce a standard .efi binary, then integrate it into
the firmware device (FD) build process.
2. Add support to the EDK2 build infrastructure to compile Rust source code alongside the C source code when processing
each module specified in a DSC file.

Option **(2)** is a viable solution and this repository has several examples, but the primary method to ingest the Patina
DXE core is by using option **(1)** since it allows for a more natural development experience using only Rust tools and
processes, and it greatly simplifies the integration.

## Option 1 Usage - Adding a DXE Core Driver .efi binary into the build

The following list outlines the items and steps used by the GitHub actions to produce a bootable .FD image that includes
the Patina DXE Core driver and can be executed in QEMU

1) The [Patina DXE Core](https://github.com/OpenDevicePartnership/patina-dxe-core-qemu) repository contains code to build
a fully Rust based DXE core driver targeted toward either the SBSA or Q35 platform.
2) That repository has a [Constant Integration](https://github.com/???) action that creates a stand-alone .efi DXE Core
binary that is published to a nuget feed
3) The [Patina QEMU UEFI](https://github.com/) repository (this repo) has a [Constant Integration](https://github.com/???)
action that executes stuart_update which pulls the pre-compiled .efi DXE core driver from its nuget feed and places it in
the tree.
4) The [QemuSbsaPkg/QemuSbsaPkg.fdf](https://github.com/) and [QemuSbsaPkg/QemuSbsaPkg.fdf](https://github.com/) files contain
an entry to define the pre-compiled binary to use instead of the typical line that instructs the build to use the binary
produced when compiling modules in the .dsc file.

### Replacing the .efi Binary - Modify .fdf file

If building this UEFI locally and you want to add a different .efi binary, the easiest method is to update the ```FILE DXE_CORE```
section to point to the file you want to include and re-compile.  The .fdf files contain several lines to allow overrides
and selecting nuget debug or release flavors which can all be replaced with the following sample entry.

```text
  FILE DXE_CORE = 23C9322F-2AF2-476A-BC4C-26BC88266C71 {
    SECTION PE32 = "<new dxe core file path>"
    SECTION UI = "DxeCore"
  }
```

### Replacing the .efi Binary - Define on command line

Another option to replace the binary is to use the DXE_CORE_BINARY_OVERRIDE define that can be set at the command line
to point to a new .efi binary without having to modify the .fdf file.

```cmd
  stuart_build -c Platforms\QemuQ35Pkg\PlatformBuild.py --FLASHROM BLD_*_DXE_CORE_BINARY_OVERRIDE="<new dxe core file path>"
```

### Replacing the .efi Binary - Patina FW Patcher

And the 3 option to use a new binary is patching the .FD file created from the build process which can be useful if multiple
iterations need to be tested.  The platform .fdf files place the DXE Core in it's own firmware volume which can be replaced
after compilation by using the [Patina FW Patcher](https://github.com/OpenDevicePartnership/patina-fw-patcher) to open an
existing UEFI FD binary, find and replace the current DXE Core driver, and launch QEMU with the patched ROM image.

The [build_and_run_rust_binary.py](https://github.com/OpenDevicePartnership/patina-qemu/blob/main/build_and_run_rust_binary.py)
script is provided in the root of this repository to perform all steps necessary to compile the Patina DXE core driver,
call the patcher, and start QEMU.  For more details, run it with the `--help` command line parameter:

```cmd
  python build_and_run_rust_binary.py --help
```

Note that this tool is not a general FW patcher to be used on any UEFI FD image due to relying on specific features
implemented in this UEFI build.  Because this tool is patching an existing QEMU ROM image, only changes to the Rust
DXE Core code will be merged and any changes to the C code will require running a full stuart_build process.

The tool can be enhanced to patch more than the Patina DXE Core.  If there is interest in new features, please start
a discussion in the tool's repo [discussions](https://github.com/OpenDevicePartnership/patina-fw-patcher/discussions/categories/q-a)
area.






TO DO - Option 2







As of today, [tianocore/edk2](https://github.com/tianocore/edk2) does not support option **(2)** so to support compiling
Rust code in an EDK II build process, the end user must update and maintian the build rules to handle the Rust toolchain.
This coupling of the EDK II build system with the Rust/Cargo build system introduces additional complexity alongside EDK
II workspace requirements causing friction with Rust workspace conventions. EDK II customizations such as PCDs are not
natively supported in Rust. Conversely, Rust feature flags are not supported in the EDK II build process. This further
increases integration complexity as consumers must understand multiple types of customization and how they may cooperate
with each other.

However, using option 2 does allow for linking Rust and C code in several combinations:

- **C source** + **Rust source** mixed in .inf (Library or Module)
  - Rust source code is recognized and supported by an EDK II build rule – Rust-To-Lib-File (.rs => .lib)
- **Pure Rust Module only**.
  - A Cargo.toml file is added to INF file as source.
  - Rust Module build is supported by EDK II build rule – Toml-File.RUST_MODULE (.toml => .efi)
- **Pure Rust Module** + **Pure Rust Library with Cargo Dependency**.
  - The cargo dependency means the rust lib dependency declared in Cargo.toml.
- **Pure Rust Module** + **C Library with EDK II Dependency**.
  - Rust Module build is supported by EDK II build rule – Toml-File (.toml => .lib)
  - The EDK II dependency means the EDK II lib dependency declared in INF.
    - If a rust module is built with C, the cargo must use `staticlib`. Or, `rlib` should be used.
- **C Module** + **Pure Rust Library with EDK II Dependency**.
  - Rust Lib build is supported by EDK II build rule – Toml-File. (.toml => .lib)
- **Pure Rust Module** + **Pure Rust Library with EDK II Dependency**.
  - Same as combining others from above.


. The [Patina](https://github.com/OpenDevicePartnership/patina?tab=readme-ov-file#patina)
open-source project does.

**(2)** is particularly useful for linking Rust code with C code in a given module. However, several combinations are
possible with today's support:


After experimenting with **(2)**, we have found that while it  is how most projects initially consider integrating Rust
into their codebase but in practice the integration complexity is high due to the ability to cointegrate the Rust/Carg
build system with the EDK II build system and it naturally leads to Rust source code being maintained in the C codebase
which is not ideal due to language and tooling differences.




When using option **(1)** to build a pure Rust code .efi binary, that best ensures consumers they are using a "Rust
implementation". It is possible that Rust build may have had C code linked into the binary with a FFI, but that is not
a practice in Patina.

![Rust Integration Options](./docs/images/rust_integration_options.png)









#### Local Development

The above steps will help you build and test the vanilla code, with dependencies fetched from
[crates.io](https://crates.io). For local development, you should modify the relevant crates within
the `patina` repository and update the dependencies using appropriate local path.


## Advanced Usage

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
