#!/usr/bin/env bash
# Checks all GraphQL documents of the app against the bundled Unraid schema.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
dart run tool/dump_documents.dart > "$tmp/docs.json"
[ -d tool/node_modules/graphql ] || npm install --prefix tool --no-save --silent graphql@16
node tool/validate_graphql.mjs "$tmp/docs.json"
