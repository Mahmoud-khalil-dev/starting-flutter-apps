#!/usr/bin/env bash
# The local copy of the CI gate. Run it before every commit.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '== secret files'
tool/check_secrets.sh

echo '== format'
# New code only: the file list comes from tool/legacy_paths.dart.
dart run tool/strict_dart_files.dart | xargs dart format --output=none --set-exit-if-changed

echo '== generated code'
flutter gen-l10n
git diff --exit-code -- 'lib/l10n/app_localizations*.dart'

echo '== analyze'
dart run tool/analyze_gate.dart

echo '== tests'
if [ -n "${CI:-}" ]; then
  flutter test --coverage --exclude-tags golden
else
  flutter test --coverage
fi

echo '== Cubit coverage'
dart run tool/coverage_gate.dart coverage/lcov.info

echo '== traceability'
dart run tool/traceability.dart --check

echo 'All gates passed.'
