#!/usr/bin/env bash
# nott-asc installer
# Usage:
#   curl -fsSL https://github.com/menot-you/mcp-asc/releases/latest/download/install.sh | sh
# Override INSTALL_DIR for Claude Code plugin install:
#   INSTALL_DIR=${CLAUDE_PLUGIN_ROOT}/bin curl ... | sh
set -euo pipefail

REPO="menot-you/mcp-asc"
BINARY="nott-asc"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"

detect_target() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"
    case "${os}-${arch}" in
        darwin-arm64)   echo "aarch64-apple-darwin" ;;
        darwin-x86_64)  echo "x86_64-apple-darwin" ;;
        linux-x86_64)   echo "x86_64-unknown-linux-gnu" ;;
        linux-aarch64)  echo "aarch64-unknown-linux-gnu" ;;
        *) echo "Error: unsupported platform ${os}-${arch}" >&2; exit 1 ;;
    esac
}

get_latest_version() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\(v[^"]*\)".*/\1/'
}

main() {
    echo "${BINARY} installer (menot-you/mcp-asc)"
    echo "---"
    local target version asset_url
    target="$(detect_target)"
    version="${TAG:-$(get_latest_version)}"
    if [ -z "${version}" ]; then
        echo "Error: no release found at https://github.com/${REPO}/releases" >&2
        exit 1
    fi
    echo "Target:   ${target}"
    echo "Version:  ${version}"
    echo "Dest:     ${INSTALL_DIR}/${BINARY}"
    mkdir -p "${INSTALL_DIR}"
    asset_url="https://github.com/${REPO}/releases/download/${version}/${BINARY}-${version}-${target}.tar.gz"
    echo ""
    echo "Downloading ${asset_url}..."
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT
    curl -fsSL -o "${tmp}/bundle.tar.gz" "${asset_url}"
    tar -xzf "${tmp}/bundle.tar.gz" -C "${tmp}"
    install -m 0755 "${tmp}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
    echo "Installed: ${INSTALL_DIR}/${BINARY}"
    if ! echo "${PATH}" | tr ':' '\n' | grep -qx "${INSTALL_DIR}"; then
        echo ""
        echo "Add to PATH:"
        echo "  export PATH=\"${INSTALL_DIR}:\${PATH}\""
    fi
}

main "$@"
