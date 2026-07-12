#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-HEAD}"
pattern='Color\(0x[0-9A-Fa-f]+\)|Colors\.(white|black|red|green|blue|purple|orange|grey|gray)'
violations=""

while IFS= read -r file; do
  [[ "$file" == *.dart ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ lib/src/shared/theme/(app_colors|app_theme)\.dart$ ]] && continue

  before="$(git show "$base_ref:$file" 2>/dev/null | grep -Eo "$pattern" | sort || true)"
  after="$(grep -Eo "$pattern" "$file" | sort || true)"
  added="$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"

  if [[ -n "$added" ]]; then
    while IFS= read -r token; do
      [[ -n "$token" ]] && violations+="$file: $token"$'\n'
    done <<< "$added"
  fi
done < <(git diff --name-only "$base_ref" -- lib)

violations="${violations%$'\n'}"

if [[ -n "$violations" ]]; then
  echo "Novas cores literais fora do tema central:"
  echo "$violations"
  echo
  echo "Use Theme.of(context).colorScheme ou um token semântico do tema."
  exit 1
fi

echo "Theme guard OK: nenhuma cor literal nova fora do tema central."
