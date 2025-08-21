#!/usr/bin/env bash
set -euo pipefail
file="$1"; limit="$2"
size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
if [ "$size" -gt "$limit" ]; then
  echo "FAIL: $file size $size > limit $limit bytes"; exit 1
fi
echo "OK: $file size $size <= limit $limit bytes"
