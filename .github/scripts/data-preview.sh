#!/bin/sh
# Generates a markdown preview of YAML data changes for PR comments.
# Usage: data-preview.sh <base_ref> [output_file]
set -eu

base_ref="${1:-origin/main}"
output="${2:-/dev/stdout}"

changed=$(git diff --name-only "$base_ref"...HEAD -- priv/data/ | grep '\.yml$' || true)

if [ -z "$changed" ]; then
  exit 0
fi

{
  echo "### Data Changes Preview"
  echo ""

  echo "$changed" | while IFS= read -r file; do
    if git show "$base_ref":"$file" > /dev/null 2>&1; then
      status="Modified"
    else
      status="New"
    fi

    echo "**$status:** \`$file\`"

    if [ "$status" = "Modified" ]; then
      diff_output=$(git diff "$base_ref"...HEAD -- "$file" | grep '^[+-]' | grep -v '^[+-][+-][+-]' | head -20 || true)
      if [ -n "$diff_output" ]; then
        echo '```diff'
        echo "$diff_output"
        echo '```'
      fi
    fi
    echo ""
  done

  echo "> **Note:** Profiles claimed by users in the app will not be overwritten at deploy time."
} > "$output"
