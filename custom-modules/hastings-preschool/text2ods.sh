#!/usr/bin/env bash
set -euo pipefail
txt="$1"
[[ -f "$txt" ]] || { echo "No such file: $txt" >&2; exit 1; }
dir="$(dirname "$txt")"
base="$(basename "${txt%.*}")"
csv="$dir/$base.csv"
out="$dir/output.ods"
python3 "$HOME/.local/bin/okular2csv.py" "$txt" "$csv"
ssconvert "$csv" "$out" >/dev/null 2>&1
rm -f "$csv"
echo "✓ Wrote $out"
