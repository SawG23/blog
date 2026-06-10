#!/usr/bin/env bash

set -euo pipefail

GITHUB_USER="SawG23"
GITHUB_REPO="CTF-writeups"
BRANCH="main"
ASSET_DIR="asset"

find . -type f -name "*.md" | while read -r mdfile; do
    filename="$(basename "$mdfile" .md)"

    # Chuẩn hoá tên folder (lowercase, bỏ space)
    folder="$(echo "$filename" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

    echo "[*] Rewriting: $mdfile → asset/$folder"

    # Thay hackmd image url sang github raw
    sed -i -E \
        "s#https://hackmd.io/_uploads/([A-Za-z0-9._-]+)#https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}/${ASSET_DIR}/${folder}/\1#g" \
        "$mdfile"
done

echo "[✓] Rewrite completed."
