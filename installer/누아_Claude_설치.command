#!/bin/bash
# 더블클릭 설치용(처음 한 번은 우클릭 → 열기). 하는 일은 한 줄 설치와 같아요.
curl -fsSL https://raw.githubusercontent.com/zkxks1004-eng/claude-setup-kit/main/bootstrap.sh | bash
echo
read -r -p "설치가 끝났어요. 엔터를 누르면 창이 닫혀요." _
