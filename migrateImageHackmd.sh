#!/usr/bin/env bash

set -euo pipefail

GITHUB_USER="SawG23"
GITHUB_REPO="CTF-writeups"
BRANCH="main"
ASSET_DIR="asset"
POST_DIR="src/content/posts"

find "$POST_DIR" -type f -name "*.md" | while read -r mdfile; do
    mdname="$(basename "$mdfile" .md)"

    echo "[*] Processing: $mdfile"
    echo "    → asset/$mdname/"

    # Thay link hackmd -> github raw
    sed -i -E \
        "s#https://hackmd.io/_uploads/([A-Za-z0-9._-]+)#https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}/${ASSET_DIR}/${mdname}/\1#g" \
        "$mdfile"
done

echo "[✓] All posts rewritten successfully."
