#!/bin/bash
# 사업개발팀 Claude Code 설정 키트 (맥). 여러 번 실행해도 안전.
# 비밀값·토큰은 들어 있지 않음 — 로그인은 README의 "로그인" 단계에서 각자.
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"
ok()   { printf '  ✓ %s\n' "$1"; }
warn() { printf '  ! %s\n' "$1"; }
# 단계별 예상 시간(초) — 남은 시간 안내용
ETA=(0 20 150 90 20 5 5)
step() {
  local n=$1 left=0 i
  for ((i=n; i<=6; i++)); do left=$((left + ETA[i])); done
  printf '\n[%s/6] %s  ·  남은 시간 약 %s분\n' "$n" "$2" "$(( (left + 59) / 60 ))"
}

command -v claude >/dev/null || { echo "Claude Code가 없어요. 먼저 설치: https://claude.com/claude-code"; exit 1; }

step 1 "플러그인 마켓 6곳 추가"
for m in anthropics/claude-plugins-official anthropics/knowledge-work-plugins \
         nextlevelbuilder/ui-ux-pro-max-skill DietrichGebert/ponytail kenryu42/cc-marketplace duckdb/duckdb-skills; do
  claude plugin marketplace add "$m" >/dev/null 2>&1 && ok "$m" || warn "$m (이미 있거나 실패)"
done

step 2 "플러그인 18개 설치"
for p in superpowers@claude-plugins-official figma@claude-plugins-official playwright@claude-plugins-official \
         firecrawl@claude-plugins-official chrome-devtools-mcp@claude-plugins-official context7@claude-plugins-official \
         code-review@claude-plugins-official frontend-design@claude-plugins-official hookify@claude-plugins-official \
         claude-md-management@claude-plugins-official session-report@claude-plugins-official \
         data@knowledge-work-plugins productivity@knowledge-work-plugins operations@knowledge-work-plugins \
         ui-ux-pro-max@ui-ux-pro-max-skill ponytail@ponytail cc-safety-net@cc-marketplace duckdb-skills@duckdb-skills; do
  claude plugin install "$p" >/dev/null 2>&1 && ok "$p" || warn "$p (이미 있거나 실패)"
done

step 3 "명령줄 도구"
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v uv >/dev/null && ok "uv" || warn "uv 설치 실패"
command -v duckdb >/dev/null || curl -fsSL https://install.duckdb.org | sh
command -v duckdb >/dev/null && ok "duckdb" || warn "duckdb 설치 실패(선택)"
if ! command -v gws >/dev/null; then
  # Google Workspace CLI (github.com/googleworkspace/cli) — 최신 릴리스의 맥 arm64 바이너리
  arch=$([ "$(uname -m)" = arm64 ] && echo aarch64 || echo x86_64)
  url=$(curl -fsSL https://api.github.com/repos/googleworkspace/cli/releases/latest | grep -o "https://[^\"]*-${arch}-apple-darwin\.tar\.gz" | head -1)
  if [ -n "$url" ]; then mkdir -p "$HOME/.local/bin" && curl -fsSL "$url" | tar -xz -C "$HOME/.local/bin" ./gws 2>/dev/null; fi
fi
command -v gws >/dev/null && ok "gws" || warn "gws 자동 설치 실패 → README의 수동 설치 참고"
if command -v npm >/dev/null; then
  for n in ccstatusline firecrawl-cli @google/clasp; do npm ls -g "$n" >/dev/null 2>&1 || npm i -g "$n" >/dev/null 2>&1; done
  ok "ccstatusline · firecrawl-cli · clasp (npm)"
else
  warn "Node(npm)가 없어 상태줄·firecrawl·clasp는 건너뜀 → README 참고"
fi

step 4 "MCP 서버 5개(사용자 범위)"
claude mcp add -s user -t http figma https://mcp.figma.com/mcp >/dev/null 2>&1; ok figma
claude mcp add -s user -t http atlassian https://mcp.atlassian.com/v1/mcp >/dev/null 2>&1; ok atlassian
claude mcp add -s user -t http notion https://mcp.notion.com/mcp >/dev/null 2>&1; ok notion
claude mcp add -s user markitdown -- uvx markitdown-mcp >/dev/null 2>&1; ok markitdown
command -v clasp >/dev/null && { claude mcp add -s user clasp -- "$(command -v clasp)" mcp >/dev/null 2>&1; ok clasp; } || warn "clasp 없음(선택)"

step 5 "스킬(gws 5개) 복사"
mkdir -p "$HOME/.claude/skills"
cp -R "$KIT"/skills/gws-* "$HOME/.claude/skills/" && ok "~/.claude/skills/gws-*"

step 6 "훅·상태줄을 settings.json에 합치기(기존 설정 유지, 백업 남김)"
/usr/bin/python3 "$KIT/merge_settings.py" "$KIT/settings-snippet.json" && ok "settings.json"

printf '\n✅ 설치 끝! 설치 페이지로 돌아가 4단계(회사 계정 연결)를 해 주세요.\n'
