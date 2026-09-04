#!/bin/sh

prog_NAME="$(basename "$0")"

err() {
    echo "${prog_NAME}: ERROR: $*" 1>&2
}

die() {
    echo "${prog_NAME}: ERROR: $*" 1>&2
    exit 1
}

# Find LLVM's llvm-ar, used on macOS hosts to build for the (ELF) Solo5
# target. Sets LLVM_AR to the full path on success.
find_llvm_ar() {
    # Prefer whatever llvm-ar resolves to on PATH (Nix, MacPorts, manual
    # installs, or Homebrew with llvm added to PATH).
    LLVM_AR="$(command -v llvm-ar 2>/dev/null)"
    if [ -n "${LLVM_AR}" ]; then
        return 0
    fi
    # Homebrew's llvm keg is not on PATH by default; ask brew where it is.
    # This handles both the default (/opt/homebrew) and custom prefixes.
    if command -v brew >/dev/null 2>&1; then
        LLVM_AR="$(brew --prefix llvm 2>/dev/null)/bin/llvm-ar"
        if [ -x "${LLVM_AR}" ]; then
            return 0
        fi
    fi
    return 1
}

usage() {
    cat <<EOM 1>&2
usage: ${prog_NAME} [ OPTIONS ]
Configures the ocaml-solo5 build system.
Options:
    --prefix=DIR
        Installation prefix (default: /usr/local).
    --sysroot=DIR
        Installation prefix for the OCaml cross-compiler and its supporting
        libraries (default: <installation prefix>/lib/ocaml-solo5).
    --target=TARGET
        Solo5 compiler toolchain to use.
    --othertoolprefix=PREFIX
        Prefix for tools besides the Solo5 toolchain
        (default: \`TARGET-cc -dumpmachine\`-).
    --ocaml-configure-option=OPTION
        Add an option to the OCaml compiler configuration.
EOM
    exit 1
}

OCAML_CONFIGURE_OPTIONS=
MAKECONF_PREFIX=/usr/local

while [ $# -gt 0 ]; do
    OPT="$1"

    case "${OPT}" in
    --target=*)
        CONFIG_TARGET="${OPT#*=}"
        ;;
    --othertoolprefix=*)
        MAKECONF_TOOLPREFIX="${OPT#*=}"
        TOOLPREFIX_EXPLICIT="yes"
        ;;
    --prefix=*)
        MAKECONF_PREFIX="${OPT#*=}"
        ;;
    --sysroot=*)
        MAKECONF_SYSROOT="${OPT#*=}"
        ;;
    --ocaml-configure-option=*)
        OCAML_CONFIGURE_OPTIONS="${OCAML_CONFIGURE_OPTIONS} ${OPT#*=}"
        ;;
    --help)
        usage
        ;;
    *)
        err "Unknown option: '${OPT}'"
        usage
        ;;
    esac

    shift
done

MAKECONF_SYSROOT="${MAKECONF_SYSROOT:-$MAKECONF_PREFIX/lib/ocaml-solo5}"
MAKECONF_AR=

[ -z "${CONFIG_TARGET}" ] && die "The --target option needs to be specified."

TARGET_TRIPLET="$("$CONFIG_TARGET-cc" -dumpmachine)"

MAKECONF_TOOLPREFIX="${MAKECONF_TOOLPREFIX:-$TARGET_TRIPLET-}"

case "${TARGET_TRIPLET}" in
amd64-* | x86_64-*)
    TARGET_ARCH="x86_64"
    ;;
aarch64-*)
    TARGET_ARCH="aarch64"
    ;;
*)
    die "Unsupported build architecture: ${TARGET_TRIPLET}"
    ;;
esac

# On macOS the Solo5 toolchain is Clang/LLVM-based and there is no binutils
# for the target: 'ar', 'ranlib', etc. must come from an LLVM installation
# (the host BSD tools produce archives unusable for the target). Probe for
# LLVM unless the caller told us exactly where to look via --othertoolprefix.
case "$(uname -s)" in
Darwin)
    if [ -z "${TOOLPREFIX_EXPLICIT}" ]; then
        if find_llvm_ar; then
            MAKECONF_TOOLPREFIX="$(dirname "${LLVM_AR}")/llvm-"
        else
            err "Cannot find an LLVM toolchain, which is required on macOS."
            err "The build needs LLVM's tools (llvm-ar, etc.); the host BSD tools cannot build for the Solo5 target."
            err "Install LLVM with: brew install llvm"
            err "Alternatively, make sure 'llvm-ar' is on your PATH, or pass the location explicitly:"
            err "    --othertoolprefix=/path/to/llvm/bin/llvm-"
            exit 1
        fi
    fi
    MAKECONF_AR="$(command -v -- "${MAKECONF_TOOLPREFIX}ar" 2>/dev/null)" || {
        err "No usable 'ar' found at '${MAKECONF_TOOLPREFIX}ar'."
        err "Install LLVM with: brew install llvm, or pass its location explicitly:"
        err "    --othertoolprefix=/path/to/llvm/bin/llvm-"
        exit 1
    }
    if ! "${MAKECONF_AR}" --version 2>/dev/null | grep -qi llvm; then
        err "'${MAKECONF_AR}' does not look like LLVM's ar."
        err "On macOS the host BSD ar produces archives unusable for the (ELF) Solo5 target."
        err "Install LLVM with: brew install llvm, or pass its location explicitly:"
        err "    --othertoolprefix=/path/to/llvm/bin/llvm-"
        exit 1
    fi
    echo "${prog_NAME}: using LLVM tools from: ${MAKECONF_AR}"
    ;;
esac

cat <<EOM >Makeconf
MAKECONF_PREFIX=${MAKECONF_PREFIX}
MAKECONF_SYSROOT=${MAKECONF_SYSROOT}
MAKECONF_TOOLCHAIN=${CONFIG_TARGET}
MAKECONF_TOOLPREFIX=${MAKECONF_TOOLPREFIX}
MAKECONF_TARGET_ARCH=${TARGET_ARCH}
MAKECONF_AR=${MAKECONF_AR}
MAKECONF_OCAML_CONFIGURE_OPTIONS=${OCAML_CONFIGURE_OPTIONS}
EOM
