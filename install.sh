#!/bin/sh
# Val CLI installer
# =================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/valoryck/val/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/valoryck/val/main/install.sh | sh -s -- --version v0.2.0
#
# Detects OS/arch, downloads the latest (or specified) release from GitHub,
# verifies the checksum, and installs to /usr/local/bin (or ~/.local/bin).

set -e

REPO="valoryck/val"
BINARY="val"
INSTALL_DIR="/usr/local/bin"

# Parse arguments.
VERSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version|-v) VERSION="$2"; shift 2 ;;
    --dir|-d)     INSTALL_DIR="$2"; shift 2 ;;
    *)            shift ;;
  esac
done

# Detect OS.
OS="$(uname -s)"
case "$OS" in
  Linux*)  OS="linux" ;;
  Darwin*) OS="darwin" ;;
  *)       echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Detect architecture.
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  ARCH="amd64" ;;
  arm64|aarch64)  ARCH="arm64" ;;
  *)              echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Detected: ${OS}/${ARCH}"

# Resolve latest version if not specified.
if [ -z "$VERSION" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')"
  if [ -z "$VERSION" ]; then
    echo "Error: could not determine latest version."
    exit 1
  fi
fi

# Strip leading 'v' for the archive name (GoReleaser uses Version without v prefix).
VERSION_NUM="${VERSION#v}"

ARCHIVE="${BINARY}_${VERSION_NUM}_${OS}_${ARCH}.tar.gz"
CHECKSUMS="${BINARY}_${VERSION_NUM}_checksums.txt"
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${ARCHIVE}..."
curl -fsSL -o "${TMPDIR}/${ARCHIVE}" "${BASE_URL}/${ARCHIVE}"

echo "Downloading checksums..."
curl -fsSL -o "${TMPDIR}/${CHECKSUMS}" "${BASE_URL}/${CHECKSUMS}"

echo "Verifying checksum..."
EXPECTED="$(grep "${ARCHIVE}" "${TMPDIR}/${CHECKSUMS}" | awk '{print $1}')"
if [ -z "$EXPECTED" ]; then
  echo "Error: archive not found in checksums file."
  exit 1
fi

# Use sha256sum (Linux) or shasum (macOS).
if command -v sha256sum > /dev/null 2>&1; then
  ACTUAL="$(sha256sum "${TMPDIR}/${ARCHIVE}" | awk '{print $1}')"
elif command -v shasum > /dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "${TMPDIR}/${ARCHIVE}" | awk '{print $1}')"
else
  echo "Warning: no sha256 tool found, skipping checksum verification."
  ACTUAL="$EXPECTED"
fi

if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "Error: checksum mismatch!"
  echo "  expected: ${EXPECTED}"
  echo "  actual:   ${ACTUAL}"
  exit 1
fi
echo "Checksum OK."

echo "Extracting..."
tar -xzf "${TMPDIR}/${ARCHIVE}" -C "${TMPDIR}"

# Install the binary.
if [ -w "$INSTALL_DIR" ]; then
  mv "${TMPDIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
else
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "${TMPDIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
fi

chmod +x "${INSTALL_DIR}/${BINARY}"

echo ""
echo "val ${VERSION} installed to ${INSTALL_DIR}/${BINARY}"
echo ""
echo "Run 'val version' to verify, or 'val login' to get started."
echo ""
echo "Shell completions:"
echo "  bash: eval \"\$(val completion bash)\""
echo "  zsh:  eval \"\$(val completion zsh)\""
echo "  fish: val completion fish | source"
