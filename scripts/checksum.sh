#!/bin/sh
command -v podman >/dev/null ||
  (echo "Binary podman is missing. Install podman package." &&
    exit 1)

SCRIPT_DIR=$(cd -- "$( dirname -- "$0" )" &> /dev/null && pwd)
REPO_DIR="$(readlink -f "${SCRIPT_DIR}/..")"

echo "Building container image ..."
podman build -q -t alpine-abuilder "$REPO_DIR"

if [ "$#" -gt 0 ]; then
  for pkg in "$@"; do
    echo "Updating checksums for package: $pkg"
    podman run --rm -v "$REPO_DIR":/repo --userns keep-id \
      --entrypoint=abuild alpine-abuilder \
      -C "/repo/$pkg" checksum validate
  done
else
  echo "Usage: $0 packages..."
  echo "Example: $0 main/kwm testing/beansprout"
  exit 1
fi
