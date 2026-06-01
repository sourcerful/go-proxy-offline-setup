#!/usr/bin/env bash
set -euo pipefail

MODULES_FILE="${1:-modules.txt}"
OUTPUT_DIR="athens-storage"
# 1. Changed extension to .tgz
OUTPUT_TGZ="athens-storage.tgz" 
TMP_ROOT="$(mktemp -d)"
GOMODCACHE="$TMP_ROOT/gocache"
PACMOD_BIN="${PACMOD_BIN:-pacmod}"

if command -v cygpath >/dev/null 2>&1; then
    GOMODCACHE="$(cygpath -w "$GOMODCACHE")"
fi

echo "Reading module list from $MODULES_FILE..."

# Cleanup previous output
# 2. Updated cleanup variable
rm -rf "$OUTPUT_DIR" "$OUTPUT_TGZ"
mkdir -p "$OUTPUT_DIR"

declare -a MODULES
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue

  if [[ "$line" == \#* ]]; then
    modver="${line#\# }"
    mod="${modver% *}"
    ver="${modver##* }"
    MODULES+=("$mod@$ver")
  elif [[ "$line" == *@* ]]; then
    MODULES+=("$line")
  fi
done < "$MODULES_FILE"

echo "Found ${#MODULES[@]} modules."

for modver in "${MODULES[@]}"; do
  mod="${modver%@*}"
  ver="${modver##*@}"

  echo "Downloading $mod@$ver..."

  export GOMODCACHE
  meta=$(go mod download -json "$modver") || {
    echo "❌ Failed to download $modver"
    continue
  }
  
  moddir=$(echo "$meta" | jq -r '.Dir')
  if [[ "$moddir" == "null" || ! -d "$moddir" ]]; then
    echo "❌ Module directory not found for $modver"
    continue
  fi

  export VERSION="$ver"
  target="$(pwd)/$OUTPUT_DIR/$mod/$ver"
  # If running in Git Bash on Windows, convert target to a true Windows path for pacmod
  if command -v cygpath >/dev/null 2>&1; then
      target="$(cygpath -w "$target")"
  fi
  mkdir -p "$target"

  echo "Packing $mod@$ver using pacmod..."
  (
    cd "$moddir" || exit 1
    "$PACMOD_BIN" pack "$VERSION" "$target"
  ) || {
    echo "❌ pacmod failed on $modver. Skipping."
    continue
  }

  # Rename .zip to source.zip
  if [[ -f "$target/$VERSION.zip" ]]; then
    mv "$target/$VERSION.zip" "$target/source.zip"
  fi
  
  # Rename .mod to go.mod
  if [[ -f "$target/$VERSION.mod" ]]; then
    mv "$target/$VERSION.mod" "$target/go.mod"
  fi
done

# 3. Replaced 'zip' with 'tar'
echo "Compressing $OUTPUT_DIR into $OUTPUT_TGZ..."
tar -czf "$OUTPUT_TGZ" "$OUTPUT_DIR"

echo "Cleaning up temporary files..."
rm -rf "$TMP_ROOT"

# 4. Updated final print statement
echo "✅ Done! Output saved to: $OUTPUT_DIR and $OUTPUT_TGZ"
