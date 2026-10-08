#!/bin/bash
# 한 줄 설치용: 키트를 ~/claude-setup-kit 에 받아(이미 있으면 새로 받음) install.sh 실행. git이 없어도 됨.
set -e
DIR="$HOME/claude-setup-kit"
TMP="$(mktemp -d)"
echo "설정 키트 내려받는 중…"
curl -fsSL https://github.com/zkxks1004-eng/claude-setup-kit/archive/refs/heads/main.tar.gz | tar -xz -C "$TMP"
rm -rf "$DIR" && mv "$TMP/claude-setup-kit-main" "$DIR" && rm -rf "$TMP"
bash "$DIR/install.sh"
