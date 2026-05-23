#!/bin/sh
# vim: set ts=4 sw=4 noet:

set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)
repo_dir="$(readlink -f "${script_dir}/..")"
podman_build=0
hl="$(printf '\033[38;5;33m')"
rst="$(printf '\033[0m')"

usage() {
	cat <<-EOF
		Usage: $0 [options] [packages...]

		Options:
		  -h   Display this help
		  -p   Build in podman container

		If no packages are provided, the whole repository is built.
	EOF
}

need() {
	for bin in "$@"; do
		command -v "$bin" >/dev/null ||
			(echo "Binary ${hl}${bin}${rst} is missing." &&
				exit 1)
	done
}

build_package() {
	pkg="$1"
	case "$pkg" in
	*/*) : ;;             # already has a repo prefix
	*) pkg="main/$pkg" ;; # use main repo as default
	esac

	if [ "$podman_build" -eq 1 ]; then
		echo "Building ${hl}${pkg}${rst} in podman..."
		# TODO: Preserve apk cache across builds of multiple packages
		podman run --rm -v "$repo_dir":/repo --userns keep-id \
			--security-opt seccomp="$repo_dir"/configs/seccomp-bwrap.json \
			--entrypoint=abuild alpine-abuilder \
			-C "/repo/$pkg" rootbld
	else
		need abuild
		echo "Building ${hl}${pkg}${rst} locally..."
		REPODEST="$repo_dir/packages" \
			abuild -C "$repo_dir/$pkg" rootbld
	fi
}

build_repo() {
	if [ "$podman_build" -eq 1 ]; then
		echo "Building repository '${hl}main${rst}' from ${repo_dir} in podman ..."
		podman run --rm -v "$repo_dir":/repo --userns keep-id \
			--security-opt seccomp="$repo_dir"/configs/seccomp-bwrap.json \
			alpine-abuilder
	else
		echo "Building repository '${hl}main${rst}' from ${repo_dir} locally..."
		need buildrepo
		buildrepo -a "$repo_dir" -d "$repo_dir/packages" main
	fi
}

while getopts "hp" opt; do
	case "$opt" in
	h)
		usage
		exit 0
		;;
	p)
		podman_build=1
		;;
	*)
		usage >&2
		exit 1
		;;
	esac
done

shift $((OPTIND - 1))

if [ "$podman_build" -eq 1 ]; then
	need podman
	echo "Building container image ..."
	podman build -q -t alpine-abuilder "$repo_dir"

	# TODO: Mount signing keys if needed
fi

if [ "$#" -eq 0 ]; then
	build_repo
else
	for pkg in "$@"; do
		build_package "$pkg"
	done
fi

echo "Done."
