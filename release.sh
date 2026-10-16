#!/usr/bin/env bash
# Copy the package into a clone of https://github.com/typst/packages for a
# Typst Universe submission (one pull request per version).
#
# Usage: ./release.sh PACKAGES_CLONE
#
# Creates PACKAGES_CLONE/packages/preview/but-fit-thesis/<version> (version from
# typst.toml) with only the files the package needs; build scripts, fonts, Nix
# files and the guide stay here.
set -euo pipefail

if [ $# -ne 1 ] || [ ! -d "$1/packages" ]; then
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
fi

cd "$(dirname "$0")"
name=$(sed -n 's/^name *= *"\(.*\)"/\1/p' typst.toml)
version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' typst.toml)
target=$1/packages/preview/$name/$version

if [ -e "$target" ]; then
  echo "$target already exists; bump the version in typst.toml first." >&2
  exit 1
fi

mkdir -p "$target/docs"
cp -r typst.toml lib.typ src template thumbnail.png README.md LICENSE "$target/"
# Images shown in the README on Typst Universe (excluded from the bundle).
cp docs/*.png "$target/docs/"
echo "Copied $name $version to $target"
