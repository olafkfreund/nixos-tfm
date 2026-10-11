#!/usr/bin/env bash
# Bump sources.json to the latest clarkarch/tfm-tui release.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=clarkarch/tfm-tui
latest=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
  "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
version=${latest#v}
current=$(jq -r .version sources.json)

if [ "$version" = "$current" ]; then
  echo "tfm $current is current"
  exit 0
fi

sri() {
  curl -fsSL "https://github.com/$repo/releases/download/$latest/tfm-$1-linux.gz.sha256" |
    cut -d' ' -f1 | xargs nix hash convert --hash-algo sha256 --to sri
}

jq -n --arg v "$version" --arg x "$(sri x86_64)" --arg a "$(sri aarch64)" \
  '{version: $v, hashes: {"x86_64-linux": $x, "aarch64-linux": $a}}' >sources.json
echo "tfm $current -> $version"
