#!/usr/bin/env bash
# Fails when a file that must never be committed is tracked or would be, or
# when a tracked file holds something shaped like a live key or token.
# Example env files (env/*.example.json) are allowed: they hold no real value.
# These patterns catch the common shapes, not every secret: add a history
# scanner (gitleaks, trufflehog) in CI once the project has a remote.
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

# AWS, GitHub, Slack, OpenAI-style and Stripe live keys, and PEM private keys.
# The pattern is split so this file does not match itself.
key='(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{32,}|[sr]k_live_[A-Za-z0-9]{16,}|-----BEGIN [A-Z ]*PRIVATE'' KEY-----)'
leaks=$(printf '%s\n' "$files" | grep -v -E '^tool/check_secrets\.sh$' \
  | tr '\n' '\0' | xargs -0 grep -nIE "$key" 2>/dev/null || true)
if [ -n "$leaks" ]; then
  echo 'These lines look like a key or token. Move it to env/ or the CI secret store:' >&2
  printf '%s\n' "$leaks" | cut -c1-120 >&2
  exit 1
fi
echo 'No secret files or keys found.'
