#!/usr/bin/env bash
# Download a Zotero collection (or a whole library) as BibLaTeX into
# bib/zotero.bib through the Zotero Web API. Needs no Zotero desktop, so it
# also works on other machines and in CI. See README.md, section "Zotero".
#
# Usage: ./zotero-sync.sh
#
# Configuration (environment variables, or a zotero.env file next to this
# script; zotero.env is git-ignored because it holds the API key):
#
#   ZOTERO_LIBRARY     users/<userID> or groups/<groupID>          (required)
#   ZOTERO_COLLECTION  collection key, e.g. ABCD2345; empty = whole library
#   ZOTERO_API_KEY     read-only API key; not needed for public groups
#   ZOTERO_OUTPUT      output file, default bib/zotero.bib
#
# The file is only rewritten when its content changes, so `./build.sh -w`
# rebuilds the PDF exactly when the bibliography changed.
set -euo pipefail

cd "$(dirname "$0")"
if [ -f zotero.env ]; then
  # shellcheck disable=SC1091
  . ./zotero.env
fi

library=${ZOTERO_LIBRARY:?set ZOTERO_LIBRARY to users/<userID> or groups/<groupID> (e.g. in zotero.env)}
collection=${ZOTERO_COLLECTION:-}
output=${ZOTERO_OUTPUT:-bib/zotero.bib}
url="https://api.zotero.org/$library${collection:+/collections/$collection}/items/top"
headers=(-H "Zotero-API-Version: 3")
if [ -n "${ZOTERO_API_KEY:-}" ]; then
  headers+=(-H "Zotero-API-Key: $ZOTERO_API_KEY")
fi

tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.headers"' EXIT

# The API returns at most 100 items per request. Sorting by the date added
# keeps the order stable, so new items are appended and git diffs stay small.
start=0
total=1
while [ "$start" -lt "$total" ]; do
  curl -fsS -D "$tmp.headers" "${headers[@]}" \
    "$url?format=biblatex&sort=dateAdded&direction=asc&limit=100&start=$start" >>"$tmp"
  total=$(tr -d '\r' <"$tmp.headers" | awk -F': ' 'tolower($1) == "total-results" { print $2 }')
  total=${total:-0}
  start=$((start + 100))
done

entries=$(grep -c '^@' "$tmp" || true)
if [ -f "$output" ] && cmp -s "$tmp" "$output"; then
  echo "$output unchanged ($entries entries)"
else
  cat "$tmp" >"$output"
  echo "$output updated ($entries entries)"
fi
