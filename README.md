# ocaml-solo5 -- OCaml compiler with Solo5 backend

This package provides a OCaml compiler suitable for linking with a
Solo5 base layer:

- package versions ≥ 1.0 and the `main` branch are compatible with OCaml 5+
  compilers, see the “[Supported compiler versions]” section for details,
- package versions 0.8.x and the `4.14` branch are compatible with OCaml 4.14
  compilers.

[Supported compiler versions]: #supported-compiler-versions

## macOS

macOS on arm64 (Apple Silicon) is supported. The build requires an
LLVM installation (the Solo5 toolchain is Clang-based and the host BSD tools
cannot build for the ELF Solo5 target):

    brew install llvm

as well as Solo5, e.g. via OPAM (`opam install solo5`).

`configure.sh` locates the LLVM tools (`llvm-ar`, etc.) first on `PATH`, then
by asking `brew --prefix llvm` (this works with both the default and custom
Homebrew prefixes). Non-Homebrew installs (MacPorts, Nix, manual) work as
long as `llvm-ar` is on `PATH`; note that versioned binary names (e.g.
`llvm-ar-mp-19`) are not probed. If it cannot find them, it stops with an
error and a `brew install llvm` hint. The location can also be given explicitly, e.g.
`./configure.sh --othertoolprefix=/opt/homebrew/opt/llvm/bin/llvm-`; on
macOS the resolved `ar` must report an LLVM version — a prefix pointing
at the host BSD tools is rejected loudly. If the
tools then go missing before the build, the toolchain wrapper generation
fails with an error rather than silently using the host tools.

Note that the separate `ocaml-solo5-cross-aarch64` package is not an
alternative on macOS: it is only installable on Debian-based x86_64 Linux,
because it hard-depends on `solo5-cross-aarch64`, whose OPAM availability is
`arch != "arm64" & os = "linux" & os-family = "debian"` (this excludes macOS
and even arm64 Linux hosts). The restriction comes from that dependency
rather than from the cross package's own `available:` field. To build for the
aarch64 Solo5 target on macOS, use the main `ocaml-solo5` package described
above, which selects the `aarch64-solo5-none-static` target on Apple Silicon.

## License and contributions

All original contributions to this package are licensed under the standard MIT
license.

This package incorporates components derived or copied from musl libc, OpenBSD,
OpenLibm and other third parties. For full details of the licenses of these
third party components refer to the included LICENSE file.

The OCaml runtime ("OCaml Core System") built by this package is distributed
under the terms of the GNU LGPL version 2.1 with a special exception for static
or dynamic linking to produce an executable file. For details refer to the
LICENSE file included in the version of the `ocaml-src` OPAM package installed
on your system as a dependency when you build this package.

## Components

The following components are built and installed, where `$prefix` and `$sysroot`
are the values given to the corresponding `configure` arguments (ie the value of
`opam var prefix` and `opam var <pkg>:lib` when installed via OPAM).

In `$prefix/bin`:

- the toolchain to build binaries, using the `<arch>-solo5-ocaml-` prefix.

`$sysroot` will contain the installation of the OCaml compiler and the `nolibc`
and OpenLibm support libraries.

In `$sysroot/bin`:

- `ocamlopt.{opt,byte}`: a native OCaml compiler configured for the chosen
  target.
- Some other standard tools such as the `ocaml` interpreter and
  `ocamlc.{byte,opt}` a bytecode OCaml compiler configured for the chosen
  target. Please note that the bytecode runtime is not supported.

In `$sysroot/lib/ocaml`:

- `libasmrun.a`: the OCaml native code runtime for the Solo5 target.
- The standard library.
- In `caml/`: Header files for the OCaml runtime.

In `$prefix/lib`:

- `libnolibc.a`: libc interfaces required by the OCaml runtime.
- `libopenlibm.a`: libm required by the OCaml runtime.

In `$sysroot/include`:

- Header files for `nolibc` and OpenLibm.

In `$prefix/lib/findlib.conf.d`:

- `solo5.conf`: ocamlfind definition of the cross-compilation toolchain.

### Usage

The installed compiler is able to build Solo5 executables. The Solo5 bindings
(xen, hvt, spt, ...) are chosen at link time, using the Solo5-specific
`-z solo5-abi=XXX` compiler/linker option. Linking an executable with no
bindings results in a _dummy_ executable.

To build with the Solo5 compiler toolchain, it has to be selected using
ocamlfind or dune:

- ocamlfind: `ocamlfind -toolchain solo5 ...`
- dune: `dune build -x solo5`, or add the toolchain in a build context
  in the dune workspace file.

#### Example

The `example` describes the minimal structure needed to build an ocaml-solo5
executable with dune, linked with the hvt bindings by default. It requires an
application manifest and a startup file to initialize the libc.

- Build: `dune build -x solo5`
- Run: `solo5-hvt _build/solo5/main.exe`

## Supported compiler versions

Tested against OCaml version 5.5.0. Other versions would require specific
patches (see the `patches` directory).

## Porting to a different (uni)kernel base layer

Assuming your unikernel base layer is packaged for OPAM in a similar
fashion to Solo5 this should be as simple as:

1. Adding the appropriate clauses to determine the OPAM packages required
   and `MAKECONF_CFLAGS` for compilation to `configure.sh`.
2. Implementing a `nolibc/sysdeps_yourkernel.c`.

Note that the nolibc code is intentionally strict about namespacing of APIs
and header files. If your base layer exports symbols or defines types which
conflict with nolibc then the recommended course of action is to fix your
base layer to not export anything defined by "POSIX" or "standard C".

## Updating the vendored copy of OpenLibm

OpenLibm is "vendored" into this repository using `git subtree`:

    git subtree add --prefix openlibm https://github.com/JuliaLang/openlibm.git v0.5.4 --squash

To update the vendored copy of OpenLibm to the newer upstream version `TAG`,
use the following command _on a branch_ and then file a PR:

    git subtree pull --prefix openlibm https://github.com/JuliaLang/openlibm.git TAG --squash
