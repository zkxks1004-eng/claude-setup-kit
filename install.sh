#!/bin/bash
# 누아 Claude Code 설정 키트 (맥). 공통 + 팀별 묶음. 여러 번 실행해도 안전.
# 팀은 실행 중 번호로 고르거나 NUUA_ROLE="bd planning dev" 로 미리 지정.
# 비밀값·토큰은 들어 있지 않음 — 로그인은 README의 "로그인" 단계에서 각자.
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"
ok()   { printf '  ✓ %s\n' "$1"; }
warn() { printf '  ! %s\n' "$1"; }
# 단계별 예상 시간(초) — 남은 시간 안내용
ETA=(0 20 100 60 20 5 5 600)
step() {
  local n=$1 left=0 i
  for ((i=n; i<=7; i++)); do left=$((left + ETA[i])); done
  printf '\n[%s/7] %s  ·  남은 시간 약 %s분\n' "$n" "$2" "$(( (left + 59) / 60 ))"
}

command -v claude >/dev/null || { echo "Claude Code가 없어요. 먼저 설치: https://claude.com/claude-code"; exit 1; }

# 팀 고르기 — 팀마다 필요한 것만 깔아야 Claude가 가볍고 덜 헷갈린다(플러그인·도구가 많을수록 매 대화가 무거워짐).
ROLE="${NUUA_ROLE:-}"
if [ -z "$ROLE" ] && [ -r /dev/tty ]; then
  printf '\n어느 팀이세요? 번호를 누르고 엔터 (여러 개면 띄어서, 예: 1 3)\n  1) 사업개발팀   2) 서비스기획팀   3) 개발   0) 공통만\n> '
  read -r ans </dev/tty || ans=""
  for a in $ans; do case $a in 1) ROLE="$ROLE bd";; 2) ROLE="$ROLE planning";; 3) ROLE="$ROLE dev";; esac; done
fi
has() { case " $ROLE " in *" $1 "*) return 0;; esac; return 1; }
printf '\n설치할 묶음: 공통%s%s%s\n' "$(has bd && echo ' + 사업개발')" "$(has planning && echo ' + 서비스기획')" "$(has dev && echo ' + 개발')"

OFF=claude-plugins-official; KW=knowledge-work-plugins
MARKETS="anthropics/claude-plugins-official anthropics/knowledge-work-plugins kenryu42/cc-marketplace zkxks1004-eng/claude-setup-kit"
PLUGINS="cc-safety-net@cc-marketplace productivity@$KW nuua-common@nuua"
if has bd; then
  MARKETS="$MARKETS duckdb/duckdb-skills"
  PLUGINS="$PLUGINS data@$KW operations@$KW duckdb-skills@duckdb-skills firecrawl@$OFF figma@$OFF"
fi
has planning && PLUGINS="$PLUGINS figma@$OFF product-management@$KW nuua-planning@nuua"
if has dev; then
  MARKETS="$MARKETS nextlevelbuilder/ui-ux-pro-max-skill DietrichGebert/ponytail"
  PLUGINS="$PLUGINS superpowers@$OFF playwright@$OFF chrome-devtools-mcp@$OFF context7@$OFF code-review@$OFF frontend-design@$OFF hookify@$OFF claude-md-management@$OFF session-report@$OFF ui-ux-pro-max@ui-ux-pro-max-skill ponytail@ponytail"
fi
PLUGINS=$(printf '%s\n' $PLUGINS | awk '!s[$0]++')  # 겹치는 것(figma) 한 번만

step 1 "플러그인 마켓 추가"
for m in $MARKETS; do
  claude plugin marketplace add "$m" >/dev/null 2>&1 && ok "$m" || warn "$m (이미 있거나 실패)"
done
claude plugin marketplace update nuua >/dev/null 2>&1  # 누아 스킬은 늘 최신으로

step 2 "플러그인 $(printf '%s\n' $PLUGINS | wc -l | tr -d ' ')개 설치"
for p in $PLUGINS; do
  claude plugin install "$p" >/dev/null 2>&1 && ok "$p" || warn "$p (이미 있거나 실패)"
done

step 3 "명령줄 도구"
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v uv >/dev/null && ok "uv" || warn "uv 설치 실패"
if command -v npm >/dev/null; then
  npm ls -g ccstatusline >/dev/null 2>&1 || npm i -g ccstatusline >/dev/null 2>&1
  ok "ccstatusline (npm)"
else
  warn "Node(npm)가 없어 상태줄은 건너뜀 → README 참고"
fi
if has bd; then
  command -v duckdb >/dev/null || curl -fsSL https://install.duckdb.org | sh
  command -v duckdb >/dev/null && ok "duckdb" || warn "duckdb 설치 실패(선택)"
  if ! command -v gws >/dev/null; then
    # Google Workspace CLI (github.com/googleworkspace/cli) — 최신 릴리스의 맥 바이너리
    arch=$([ "$(uname -m)" = arm64 ] && echo aarch64 || echo x86_64)
    url=$(curl -fsSL https://api.github.com/repos/googleworkspace/cli/releases/latest | grep -o "https://[^\"]*-${arch}-apple-darwin\.tar\.gz" | head -1)
    if [ -n "$url" ]; then mkdir -p "$HOME/.local/bin" && curl -fsSL "$url" | tar -xz -C "$HOME/.local/bin" ./gws 2>/dev/null; fi
  fi
  command -v gws >/dev/null && ok "gws" || warn "gws 자동 설치 실패 → README의 수동 설치 참고"
  if command -v npm >/dev/null; then
    for n in firecrawl-cli @google/clasp; do npm ls -g "$n" >/dev/null 2>&1 || npm i -g "$n" >/dev/null 2>&1; done
    ok "firecrawl-cli · clasp (npm)"
  fi
fi

step 4 "MCP 서버(사용자 범위)"
claude mcp add -s user -t http atlassian https://mcp.atlassian.com/v1/mcp >/dev/null 2>&1; ok atlassian
claude mcp add -s user markitdown -- uvx markitdown-mcp >/dev/null 2>&1; ok "markitdown(PDF·엑셀→글)"
if has bd; then
  claude mcp add -s user -t http notion https://mcp.notion.com/mcp >/dev/null 2>&1; ok notion
  command -v clasp >/dev/null && { claude mcp add -s user clasp -- "$(command -v clasp)" mcp >/dev/null 2>&1; ok clasp; } || warn "clasp 없음(선택)"
fi
# figma는 플러그인 안에 MCP가 들어 있어 따로 추가하면 두 번 뜬다 → 예전 키트가 넣은 것 정리
case "$PLUGINS" in *figma@*) claude mcp remove -s user figma >/dev/null 2>&1 && ok "figma 중복 MCP 정리";; esac

step 5 "스킬 복사"
if has bd; then
  mkdir -p "$HOME/.claude/skills"
  cp -R "$KIT"/skills/gws-* "$HOME/.claude/skills/" && ok "~/.claude/skills/gws-*(구글 시트·드라이브)"
else
  ok "추가로 복사할 스킬 없음"
fi

step 6 "훅·상태줄을 settings.json에 합치기(기존 설정 유지, 백업 남김)"
/usr/bin/python3 "$KIT/merge_settings.py" "$KIT/settings-snippet.json" && ok "settings.json"

step 7 "회의 녹음 받아쓰기(transcribe) — 모델 1.6GB라 가장 오래 걸려요"
# 내 맥 안에서만 도는 음성 인식(whisper.cpp + large-v3-turbo). 녹음이 밖으로 나가지 않음.
W="$HOME/tools/whisper.cpp"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install >/dev/null 2>&1
  warn "맥 개발 도구 설치 창이 떴어요 → 「설치」를 누르고 끝나면 이 설치를 한 번 더 실행해 주세요(나머지는 다 됐어요)."
else
  if [ ! -x "$W/build/bin/whisper-cli" ]; then
    CMAKE=$(command -v cmake || echo "$HOME/Library/Python/3.9/bin/cmake")
    [ -x "$CMAKE" ] || { /usr/bin/python3 -m pip install --user -q cmake >/dev/null 2>&1; CMAKE="$HOME/Library/Python/3.9/bin/cmake"; }
    if [ ! -d "$W" ]; then
      mkdir -p "$HOME/tools" && curl -fsSL https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.9.5.tar.gz | tar -xz -C "$HOME/tools" \
        && mv "$HOME/tools/whisper.cpp-1.9.5" "$W"
    fi
    printf '  … 음성 인식 프로그램 만드는 중(1분 안팎)\n'
    ( cd "$W" && "$CMAKE" -B build -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && "$CMAKE" --build build -j --config Release --target whisper-cli >/dev/null 2>&1 ) \
      && ok "whisper.cpp" || warn "whisper.cpp 빌드 실패(성훈님께 화면 캡처 보내 주세요)"
  else ok "whisper.cpp(이미 있음)"; fi
  M="$W/models/ggml-large-v3-turbo.bin"
  if [ ! -s "$M" ] || [ "$(stat -f%z "$M")" -lt 1600000000 ]; then
    printf '  … 음성 인식 모델 내려받는 중(1.6GB, 인터넷에 따라 3~10분)\n'
    mkdir -p "$W/models" && curl -fL -# -C - -o "$M" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin \
      && ok "모델" || warn "모델 받기 실패 → 이 설치를 다시 실행하면 이어서 받아요"
  else ok "모델(이미 있음)"; fi
  mkdir -p "$HOME/.local/bin" && cp "$KIT/bin/transcribe" "$HOME/.local/bin/transcribe" && chmod +x "$HOME/.local/bin/transcribe" && ok "transcribe 명령"
  grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

printf '\n✅ 설치 끝! 설치 페이지로 돌아가 4단계(회사 계정 연결)를 해 주세요.\n'
