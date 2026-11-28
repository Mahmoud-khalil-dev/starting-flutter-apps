#!/usr/bin/env bash
# Validate the skill package before a release. Runs the same locally and in CI.
#
#   scripts/validate.sh
#
# Checks: SKILL.md front matter, plugin manifests, every path SKILL.md names,
# shell syntax, one Flutter pin, the scaffolder dry run, leaked secrets and machine paths.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
skill="$root/skills/starting-new-projects"
fail=0
ok() { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1" >&2; fail=1; }

echo "SKILL.md front matter"
python3 - "$skill/SKILL.md" <<'PY' && ok "name and description" || bad "front matter"
import re, sys, os
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
assert m, "no front matter block"
fields = dict(l.split(":", 1) for l in m.group(1).splitlines() if ":" in l)
name = fields.get("name", "").strip()
desc = fields.get("description", "").strip()
folder = os.path.basename(os.path.dirname(sys.argv[1]))
assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name), f"bad name: {name!r}"
assert name == folder, f"name {name!r} != folder {folder!r}"
assert len(name) <= 64, "name over 64 characters"
assert 0 < len(desc) <= 1024, f"description length {len(desc)}"
PY

echo "Plugin manifests"
for f in "$root/.claude-plugin/plugin.json" "$root/.claude-plugin/marketplace.json"; do
  python3 -m json.tool "$f" >/dev/null && ok "${f#"$root"/}" || bad "${f#"$root"/} is not valid JSON"
done
python3 - "$root" <<'PY' && ok "versions and names agree" || bad "manifest mismatch"
import json, sys, re
root = sys.argv[1]
plugin = json.load(open(f"{root}/.claude-plugin/plugin.json"))
market = json.load(open(f"{root}/.claude-plugin/marketplace.json"))
assert plugin["name"] in [p["name"] for p in market["plugins"]]
assert re.fullmatch(r"\d+\.\d+\.\d+", plugin["version"])
changelog = open(f"{root}/CHANGELOG.md").read()
assert f"## [{plugin['version']}]" in changelog, "version missing from CHANGELOG.md"
PY

echo "Paths named in SKILL.md exist"
missing=0
while IFS= read -r p; do
  [ -e "$skill/$p" ] || { bad "missing $p"; missing=1; }
done < <(grep -oE '`(assets|references|scripts)/[^`<> ]+`' "$skill/SKILL.md" | tr -d '`' | sort -u)
[ "$missing" -eq 0 ] && ok "all referenced paths"

echo "Shell syntax"
while IFS= read -r f; do
  bash -n "$f" && ok "${f#"$root"/}" || bad "${f#"$root"/}"
done < <(find "$root/scripts" "$skill/scripts" "$skill/assets/flutter-kit/tool" -type f \( -name '*.sh' -o -name 'new-flutter-app' \))
if command -v shellcheck >/dev/null; then
  shellcheck -S error "$root/scripts/validate.sh" "$skill/scripts/new-flutter-app" && ok "shellcheck" || bad "shellcheck"
fi

echo "One Flutter pin"
pins=$(cat "$root/.github/workflows/validate.yml" "$skill/assets/flutter-kit/.github/workflows/verify.yml" \
  | sed -n 's/^ *flutter-version: *//p' | sort -u)
[ "$(printf '%s\n' "$pins" | grep -c .)" -eq 1 ] && ok "flutter-version $pins in every workflow" \
  || bad "flutter-version differs between workflows: $(echo $pins)"

echo "Scaffolder dry run"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$tmp" && "$skill/scripts/new-flutter-app" "Validate App" --org com.example --dry-run >/dev/null) \
  && ok "new-flutter-app --dry-run" || bad "new-flutter-app --dry-run"

echo "No secrets or machine paths"
patterns=$'(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(^|[^A-Za-z0-9_.])/(Users|home)/[a-z]+/)'
hits=$(cd "$root" && git ls-files -z 2>/dev/null | xargs -0 grep -nIE "$patterns" 2>/dev/null \
  | grep -vE '^scripts/validate\.sh:|/test/|/Users/someone/|app_log\.dart' || true)
[ -z "$hits" ] && ok "clean" || { echo "$hits" >&2; bad "possible secret or machine path"; }
keyfiles=$(cd "$root" && git ls-files 2>/dev/null | grep -E '\.(p8|p12|pem|jks|keystore|mobileprovision)$|(^|/)\.env$|google-services\.json|GoogleService-Info\.plist' || true)
[ -z "$keyfiles" ] && ok "no key files" || { echo "$keyfiles" >&2; bad "key file tracked"; }

echo "No unfilled placeholders outside templates"
ph=$(grep -rnE '\{\{[A-Z_]+\}\}' "$skill/SKILL.md" "$skill/references" "$root/README.md" || true)
[ -z "$ph" ] && ok "clean" || { echo "$ph" >&2; bad "placeholder outside assets/templates"; }

[ "$fail" -eq 0 ] && echo "All checks passed." || { echo "Validation failed." >&2; exit 1; }
