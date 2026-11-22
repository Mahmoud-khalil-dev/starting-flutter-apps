#!/usr/bin/env bash
# Fails when a file that must never be committed is tracked or would be.
# Example env files (env/*.example.json) are allowed: they hold no real value.
# Scan the history in CI with a secret scanner of your choice.
set -euo pipefail
cd "$(dirname "$0")/.."

pattern='\.(p8|p12|jks|keystore|mobileprovision)$|(^|/)key\.properties$|adminsdk[^/]*\.json$|^env/[^/]*\.json$|(^|/)\.env(\.|$)'

files=$(git ls-files --cached --others --exclude-standard)
found=$(printf '%s\n' "$files" | grep -E "$pattern" | grep -v -E '^env/[^/]*\.example\.json$' || true)
if [ -n "$found" ]; then
  echo 'These files must not enter the repository:' >&2
  printf '%s\n' "$found" >&2
  exit 1
fi
echo 'No secret files found.'
