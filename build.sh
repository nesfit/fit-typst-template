#!/usr/bin/env bash
# Compile the thesis to PDF, once or on every change.
#
# Usage: ./build.sh [-w|--watch] [-o|--open] [SOURCE.typ [OUTPUT.pdf]]
#
#   -w, --watch   rebuild whenever a source file changes (Ctrl+C to stop)
#   -o, --open    open the PDF after the first successful build
#
# SOURCE defaults to template/thesis.typ, OUTPUT to thesis.pdf; both are
# relative to the repository root. The `@preview/but-fit-thesis` import in the
# template resolves to this checkout, not to the published package.
#
# Uses `typst` from PATH (e.g. inside `nix develop`), otherwise `tinymist`
# from PATH or the one downloaded by Zed's Typst extension, which embeds the
# Typst compiler. Works on Linux, macOS and Windows (Git Bash / MSYS2).
set -euo pipefail

usage() { sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; }

watch=false
open=false
args=()
while [ $# -gt 0 ]; do
  case $1 in
    -w | --watch) watch=true ;;
    -o | --open) open=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *) args+=("$1") ;;
  esac
  shift
done
source_file=${args[0]:-template/thesis.typ}
output_file=${args[1]:-$(basename "${source_file%.typ}").pdf}
output_path=./${output_file#./}

cd "$(dirname "$0")"

log() {
  if [ -t 1 ]; then
    printf '\033[%sm[%s] %s\033[0m\n' "$1" "$(date +%H:%M:%S)" "$2"
  else
    printf '[%s] %s\n' "$(date +%H:%M:%S)" "$2"
  fi
}

zed_typst_dir() {
  case $(uname -s) in
    Darwin) echo "$HOME/Library/Application Support/Zed/extensions/work/typst" ;;
    MINGW* | MSYS* | CYGWIN*) echo "$(cygpath -u "${LOCALAPPDATA:-}")/Zed/extensions/work/typst" ;;
    *) echo "${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions/work/typst" ;;
  esac
}

find_zed_tinymist() {
  local dir bin candidates
  dir=$(zed_typst_dir)
  if [ -f "$dir/latest-binary" ]; then
    bin="$dir/$(tr -d '\r\n' <"$dir/latest-binary")"
    [ -x "$bin" ] && echo "$bin" && return
  fi
  candidates=("$dir"/tinymist-v*/tinymist*)
  bin=${candidates[${#candidates[@]} - 1]}
  [ -x "$bin" ] && echo "$bin"
}

open_pdf() {
  case $(uname -s) in
    Darwin) open "$output_file" ;;
    MINGW* | MSYS* | CYGWIN*) explorer.exe "$(cygpath -w "$output_file")" || true ;;
    *) xdg-open "$output_file" >/dev/null 2>&1 & ;;
  esac
}

if command -v typst >/dev/null; then
  compiler=typst
elif command -v tinymist >/dev/null; then
  compiler=tinymist
elif ! compiler=$(find_zed_tinymist); then
  echo "No Typst compiler found: install typst, enter 'nix develop', or add the Typst extension to Zed." >&2
  exit 1
fi
log 90 "Using $compiler"

# Fonts bundled with the template (Open Sans, New Computer Modern Mono).
case $(uname -s) in
  MINGW* | MSYS* | CYGWIN*) font_sep=';' ;;
  *) font_sep=':' ;;
esac
export TYPST_FONT_PATHS="fonts${TYPST_FONT_PATHS:+$font_sep$TYPST_FONT_PATHS}"

# Serve this checkout as @preview/but-fit-thesis:<version>: Typst looks into the
# local package directory first, for every namespace.
version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' typst.toml)
package_dir=.typst-packages/preview/but-fit-thesis
if [ ! -e "$package_dir/$version" ]; then
  # Never recurse: the entries are links to this checkout.
  rm -f "$package_dir"/* 2>/dev/null || true
  mkdir -p "$package_dir"
  case $(uname -s) in
    # A junction needs no administrator rights or developer mode.
    MINGW* | MSYS* | CYGWIN*) MSYS2_ARG_CONV_EXCL="*" cmd.exe /c mklink /J "$(cygpath -w "$PWD/$package_dir/$version")" "$(cygpath -w "$PWD")" >/dev/null ;;
    *) ln -s ../../.. "$package_dir/$version" ;;
  esac
fi
export TYPST_PACKAGE_PATH=.typst-packages

build() {
  # Viewers such as Foxit or Acrobat lock the PDF on Windows; opening it for append detects that without modifying it.
  if [ -e "$output_file" ] && ! { : >>"$output_file"; } 2>/dev/null; then
    log 33 "$output_file is locked by another program (PDF viewer?), close it and save again."
    return 1
  fi
  if "$compiler" compile "$source_file" "$output_file"; then
    log 32 "Built $output_file"
  else
    log 31 "Build FAILED"
    return 1
  fi
}

if ! $watch; then
  build
  if $open; then open_pdf; fi
  exit 0
fi

# typst has a native, incremental watcher.
if [ "$(basename "$compiler")" = typst ]; then
  if $open; then
    exec "$compiler" watch "$source_file" "$output_file" --open
  else
    exec "$compiler" watch "$source_file" "$output_file"
  fi
fi

# tinymist has no watch mode, so poll the inputs and rebuild on change.
inputs() {
  find . \( -name .git -o -name .typst-packages \) -prune -o -type f \
    \( -name '*.typ' -o -name '*.yaml' -o -name '*.yml' -o -name '*.bib' -o -name '*.csl' \
    -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.svg' -o -name '*.pdf' \) \
    ! -path "$output_path" "$@" -print
}

stamp=$(mktemp)
trap 'rm -f "$stamp"' EXIT

log 90 "Watching for changes, press Ctrl+C to stop."
listing=$(inputs | sort)
touch "$stamp"
if build && $open; then open_pdf; fi

while sleep 0.5; do
  # Edits and new files are newer than the stamp; deletions and renames change the listing.
  if [ -n "$(inputs -newer "$stamp")" ] || [ "$(inputs | sort)" != "$listing" ]; then
    # Let editors finish writing (atomic saves, multiple files) before building.
    sleep 0.3
    listing=$(inputs | sort)
    touch "$stamp"
    build || true
  fi
done
