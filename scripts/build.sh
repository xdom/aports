#!/bin/sh
command -v buildrepo >/dev/null ||
  (echo "buildrepo script missing. Install lua-aports package." &&
  exit 1)

SCRIPT_DIR=$(cd -- "$( dirname -- "$0" )" &> /dev/null && pwd)
REPO_DIR="$(readlink -f "${SCRIPT_DIR}/..")"

echo "Building repository 'main' from ${REPO_DIR} ..."
buildrepo -a "$REPO_DIR" -d "$HOME/packages" main
echo "Done."

