#!/bin/bash
# 누아 Claude Code 설정 키트 (맥). 공통 + 팀별 묶음. 여러 번 실행해도 안전.
# 팀은 실행 중 번호로 고르거나 NUUA_ROLE="bd planning dev" 로 미리 지정.
# 비밀값·토큰은 들어 있지 않음 — 로그인은 README의 "로그인" 단계에서 각자.
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"
KIT_VER=2026.10.13.2  # 키트를 고치면 날짜도 바꾸기(관리 화면에서 옛 키트 쓰는 사람이 보임 · Claude Code를 열 때 새 판 알림)
SITE=https://nuua-claude-setup.zkxks1004.workers.dev
FAILS=()
ok()   { printf '  ✓ %s\n' "$1"; }
warn() { printf '  ! %s\n' "$1"; FAILS+=("$1"); }   # ! 는 진짜 실패만(이미 있는 건 ✓)
skip() { printf '  – %s\n' "$1"; }                  # 고른 묶음에 없거나 일부러 건너뜀
# .zshrc 끝에 한 줄(마지막 줄이 줄바꿈 없이 끝나면 붙지 않게 먼저 줄바꿈)
addline() { grep -qF "$2" "$HOME/.zshrc" 2>/dev/null && return; [ -s "$HOME/.zshrc" ] && [ -n "$(tail -c1 "$HOME/.zshrc")" ] && echo >> "$HOME/.zshrc"; echo "$1" >> "$HOME/.zshrc"; }
# 단계별 예상 시간(초) — 남은 시간 안내용
ETA=(0 20 100 60 20 5 5 600)
step() {
  local n=$1 left=0 i
  for ((i=n; i<=7; i++)); do left=$((left + ETA[i])); done
  printf '\n[%s/7] %s  ·  남은 시간 약 %s분\n' "$n" "$2" "$(( (left + 59) / 60 ))"
}

command -v claude >/dev/null || { echo "Claude Code가 없어요. 먼저 설치: https://claude.com/claude-code"; exit 1; }
# 맥 개발 도구(git·python3)가 없으면 플러그인 받기·설정 합치기가 전부 실패한다 → 맨 먼저 깔고 git·python3가 생길 때까지 기다림
devtools() { local d; d=$(xcode-select -p 2>/dev/null) && [ -x "$d/usr/bin/git" ] && [ -x "$d/usr/bin/python3" ]; }
if ! devtools; then
  xcode-select --install >/dev/null 2>&1
  printf '\n맥 개발 도구가 필요해요. 방금 뜬 창에서 「설치」를 눌러 주세요(5~15분). 끝나면 자동으로 이어서 해요.\n  (창이 안 보이면 Dock이나 다른 창 뒤를 확인)\n'
  for _ in $(seq 180); do devtools && break; sleep 10; done
  devtools || { echo "  ! 30분이 지나도 설치가 안 끝났어요. 설치가 끝난 뒤 이 설치를 다시 실행해 주세요."; exit 1; }
  ok "맥 개발 도구"
fi
# 2.1.283부터 터미널이 auto mode(안전한 일은 묻지 않고 진행)로 시작한다 → 낮으면 업데이트
v=$(claude --version 2>/dev/null | awk '{print $1}')
if [ "$(printf '%s\n2.1.283\n' "$v" | sort -V | head -1)" != "2.1.283" ]; then
  printf 'Claude Code %s → 최신으로 업데이트(auto mode 쓰려면 2.1.283 이상)\n' "${v:-?}"
  claude update >/dev/null 2>&1 || warn "Claude Code 업데이트 실패 — 나중에 터미널에서 claude update"
fi

# 팀 고르기 — 팀마다 필요한 것만 깔아야 Claude가 가볍고 덜 헷갈린다(플러그인·도구가 많을수록 매 대화가 무거워짐).
ROLE="${NUUA_ROLE:-}"
if [ -z "$ROLE" ] && [ -r /dev/tty ]; then
  printf '\n어느 팀이세요? 번호를 누르고 엔터 (여러 개면 띄어서, 예: 1 3)\n  1) 사업개발팀   2) 서비스기획팀   3) 개발(기술연구소)   0) 공통만(서비스운영·그로스·글로벌·품질보안실)\n> '
  read -r ans </dev/tty || ans=""
  for a in $ans; do case $a in 1) ROLE="$ROLE bd";; 2) ROLE="$ROLE planning";; 3) ROLE="$ROLE dev";; esac; done
fi
has() { case " $ROLE " in *" $1 "*) return 0;; esac; return 1; }
printf '\n설치할 묶음: 공통%s%s%s\n' "$(has bd && echo ' + 사업개발')" "$(has planning && echo ' + 서비스기획')" "$(has dev && echo ' + 개발')"

# 고른 기준(10/12): 처음 쓰는 사람도 바로 효과 보는 것, 매 대화에 얹히는 설명·연결이 적은 것.
# knowledge-work-plugins(data·productivity·product-management 등)는 쓰지 않는 외부 서비스 연결을 8~16개씩 달고 와서
# /mcp가 로그인 요청으로 가득 차고 atlassian·notion이 세 번씩 떠서 뺐다.
OFF=claude-plugins-official
MARKETS="anthropics/claude-plugins-official kenryu42/cc-marketplace zkxks1004-eng/claude-setup-kit"
#   atlassian: 지라·컨플루언스 연결 + 공식 스킬 6개(회의록→할 일, 현황 보고, 사내 검색, 기획서→백로그, 이슈 분류)
#   skill-creator: 반복 업무를 내 스킬로 만들기 / claude-md-management: "앞으로 이렇게 해" 를 지침 파일에 정리
PLUGINS="nuua-common@nuua atlassian@$OFF cc-safety-net@cc-marketplace skill-creator@$OFF claude-md-management@$OFF"
if has bd; then
  MARKETS="$MARKETS duckdb/duckdb-skills"
  PLUGINS="$PLUGINS notion@$OFF figma@$OFF duckdb-skills@duckdb-skills firecrawl@$OFF"
fi
has planning && PLUGINS="$PLUGINS nuua-planning@nuua figma@$OFF"
has dev && PLUGINS="$PLUGINS superpowers@$OFF feature-dev@$OFF code-review@$OFF pr-review-toolkit@$OFF commit-commands@$OFF context7@$OFF playwright@$OFF frontend-design@$OFF"
PLUGINS=$(printf '%s\n' $PLUGINS | awk '!s[$0]++')  # 겹치는 것(figma) 한 번만

step 1 "플러그인 마켓 추가"
for m in $MARKETS; do
  claude plugin marketplace add "$m" >/dev/null 2>&1 && ok "$m" || warn "플러그인 마켓 $m 추가 실패(인터넷·GitHub 확인)"
done
claude plugin marketplace update nuua >/dev/null 2>&1 || warn "누아 마켓 새로 받기 실패"

step 2 "플러그인 $(printf '%s\n' $PLUGINS | wc -l | tr -d ' ')개 설치"
# 이미 깔린 건 건드리지 않음(내가 꺼 둔 플러그인을 다시 켜지 않게). 누아 플러그인만 최신으로 올림
HAVE=$(claude plugin list --json 2>/dev/null | /usr/bin/python3 -c 'import json,sys; print("\n".join(p["id"] for p in json.load(sys.stdin)))' 2>/dev/null)
for p in $PLUGINS; do
  if printf '%s\n' "$HAVE" | grep -qxF "$p"; then
    case $p in *@nuua) claude plugin update "$p" >/dev/null 2>&1 && ok "$p (최신으로)" || warn "$p 업데이트 실패";; *) ok "$p (이미 있음)";; esac
  else
    claude plugin install "$p" >/dev/null 2>&1 && ok "$p" || warn "플러그인 $p 설치 실패"
  fi
done

step 3 "명령줄 도구"
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
command -v uv >/dev/null && ok "uv" || warn "uv 설치 실패 — 문서 변환(markitdown) 연결이 안 돼요"
# Node가 없으면 관리자 비밀번호 없이 ~/.local/node에 공식 LTS(체크섬 확인). 상태줄·위험 명령 차단(cc-safety-net)·브라우저 연결 도구가 Node로 돈다
NODE="$HOME/.local/node"
if ! command -v npm >/dev/null && [ ! -x "$NODE/bin/npm" ]; then
  a=$(uname -m); [ "$a" = x86_64 ] && a=x64
  v=$(curl -fsSL --max-time 20 https://nodejs.org/dist/index.json | /usr/bin/python3 -c 'import json,sys; print(next(x["version"] for x in json.load(sys.stdin) if x["lts"]))' 2>/dev/null)
  f="node-$v-darwin-$a.tar.gz"; t=$(mktemp -d)
  if [ -n "$v" ] && curl -fsSL -o "$t/$f" "https://nodejs.org/dist/$v/$f" \
    && curl -fsSL "https://nodejs.org/dist/$v/SHASUMS256.txt" | grep " $f\$" | (cd "$t" && shasum -a 256 -c -s -) \
    && mkdir -p "$NODE" && tar -xzf "$t/$f" -C "$NODE" --strip-components 1; then
    ok "Node $v (~/.local/node)"
  else
    warn "Node 설치 실패 — 위험 명령 차단(cc-safety-net)·상태줄·브라우저 연결 도구가 안 돼요. 설치를 다시 실행해 보고 안 되면 캡처해 주세요"
  fi
  rm -rf "$t"
fi
if [ -x "$NODE/bin/npm" ]; then
  export PATH="$NODE/bin:$PATH"
  addline 'export PATH="$HOME/.local/node/bin:$PATH"' '.local/node/bin'
fi
# npm 전역 설치: 안 되면(nodejs.org 설치판은 관리자 폴더라 권한 오류) ~/.local에. 명령이 실제로 생겼는지로 확인
npmi() { command -v "$1" >/dev/null || npm i -g "$2" >/dev/null 2>&1 || npm i -g --prefix "$HOME/.local" "$2" >/dev/null 2>&1; command -v "$1" >/dev/null; }
if command -v npm >/dev/null; then
  npmi ccstatusline ccstatusline && ok "상태줄(ccstatusline)" || warn "상태줄(ccstatusline) 설치 실패 — 상태줄이 비어 보여요"
else
  skip "Node가 없어 상태줄은 건너뜀"
fi
if has bd; then
  command -v duckdb >/dev/null || curl -fsSL https://install.duckdb.org | sh >/dev/null 2>&1
  command -v duckdb >/dev/null && ok "duckdb" || warn "duckdb 설치 실패(선택 — 큰 엑셀·CSV 분석용)"
  if command -v npm >/dev/null; then
    npmi firecrawl firecrawl-cli && ok "firecrawl-cli" || warn "firecrawl-cli 설치 실패(선택)"
    npmi clasp @google/clasp && ok "clasp" || warn "clasp 설치 실패(선택)"
  fi
fi

step 4 "MCP 서버(사용자 범위)"
mcpadd() { claude mcp get "$1" >/dev/null 2>&1 || claude mcp add -s user "$@" >/dev/null 2>&1; }
mcpadd markitdown -- uvx markitdown-mcp && ok "markitdown(PDF·엑셀→글)" || warn "markitdown 연결 추가 실패"
if has bd; then
  command -v clasp >/dev/null && { mcpadd clasp -- "$(command -v clasp)" mcp && ok clasp || warn "clasp 연결 추가 실패"; } || skip "clasp 없음(선택)"
fi

step 5 "훅·상태줄을 settings.json에 합치기(기존 설정 유지, 백업 남김)"
/usr/bin/python3 "$KIT/merge_settings.py" "$KIT/settings-snippet.json" >/dev/null 2>&1 && ok "settings.json(백업: settings.json.nuua-first · nuua-last)" \
  || warn "~/.claude/settings.json 형식이 깨져 있어 훅·상태줄을 못 넣었어요(파일은 그대로) — 캡처해서 설치 담당자에게"
mkdir -p "$HOME/.local/bin" && cp "$KIT/bin/nuua-check" "$KIT/bin/nuua-hint" "$HOME/.local/bin/" && chmod +x "$HOME/.local/bin/nuua-check" "$HOME/.local/bin/nuua-hint" \
  && ok "nuua-check(내 맥 점검) · 여는 순간 안내(새 판·Node 없음)" || warn "nuua-check 복사 실패"
addline 'export PATH="$HOME/.local/bin:$PATH"' '.local/bin'

step 6 "사용 현황 연결(대화 내용은 보내지 않아요)"
# 질문 횟수·사용 시간·쓴 기능만 회사 관리 화면으로. 대화·파일·도구 내용은 안 보냄(아래 LOG_*·RAW_API_BODIES = 0, 트레이스 끔).
# 회사에 저장되는 건 설치 페이지 6단계에서 등록·동의한 뒤부터(그 전 신호는 서버가 버림).
# 끄기: NUUA_NO_TELEMETRY=1 → 끄고 표시 파일을 남겨 다음 설치에서도 계속 꺼 둠. 다시 켜기: NUUA_TELEMETRY=1
OPT="$HOME/.claude/.nuua-no-telemetry"
[ "${NUUA_TELEMETRY:-}" = 1 ] && rm -f "$OPT"
if [ "${NUUA_NO_TELEMETRY:-}" = 1 ] || [ -f "$OPT" ]; then
  mkdir -p "$HOME/.claude" && touch "$OPT"
  /usr/bin/python3 "$KIT/merge_settings.py" "$KIT/settings-snippet.json" --no-telemetry >/dev/null 2>&1 \
    && ok "사용 현황 보내기 꺼 둠(다시 켜려면 NUUA_TELEMETRY=1을 붙여 설치)" || warn "사용 현황 끄기 실패 — 캡처해서 설치 담당자에게"
else
  T=""; for t in bd planning dev; do has $t && T="${T:+${T}_}$t"; done
  ENVF=$(mktemp)
  if ! curl -fsSL --max-time 20 "$SITE/api/telemetry-config" | /usr/bin/python3 -c '
import json, sys
c, team, kit = json.load(sys.stdin), sys.argv[1], sys.argv[2]
json.dump({"CLAUDE_CODE_ENABLE_TELEMETRY": "1", "OTEL_METRICS_EXPORTER": "otlp", "OTEL_LOGS_EXPORTER": "otlp",
  "OTEL_EXPORTER_OTLP_PROTOCOL": "http/json", "OTEL_EXPORTER_OTLP_ENDPOINT": c["endpoint"], "OTEL_EXPORTER_OTLP_HEADERS": c["headers"],
  "OTEL_METRIC_EXPORT_INTERVAL": str(c["metric_interval"]), "OTEL_LOGS_EXPORT_INTERVAL": str(c["logs_interval"]),
  "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE": "delta",
  "OTEL_RESOURCE_ATTRIBUTES": f"nuua.team={team},nuua.kit={kit}",
  "OTEL_LOG_USER_PROMPTS": "0", "OTEL_LOG_TOOL_DETAILS": "0", "OTEL_LOG_ASSISTANT_RESPONSES": "0", "OTEL_LOG_TOOL_CONTENT": "0",
  "OTEL_LOG_RAW_API_BODIES": "0", "CLAUDE_CODE_ENHANCED_TELEMETRY_BETA": "0", "OTEL_TRACES_EXPORTER": "none"}, sys.stdout)
' "${T:-common}" "$KIT_VER" > "$ENVF" 2>/dev/null; then
    warn "사용 현황 설정을 못 받았어요(인터넷 확인) — 나중에 설치를 다시 하면 연결돼요"
  else
    /usr/bin/python3 "$KIT/merge_settings.py" "$KIT/settings-snippet.json" "$ENVF" >/dev/null 2>&1
    case $? in
      0) ok "사용 현황 연결(새로 여는 Claude Code부터 · 저장은 설치 페이지 6단계 등록 뒤부터 · 끄려면 NUUA_NO_TELEMETRY=1로 다시 설치)";;
      3) skip "직접 설정한 사용 현황 보내기(OTEL 주소)가 있어서 건드리지 않았어요";;
      *) warn "~/.claude/settings.json 형식이 깨져 있어 사용 현황 연결을 못 했어요 — 캡처해서 설치 담당자에게";;
    esac
  fi
  rm -f "$ENVF"
fi
date +%s > "$KIT/.settings_at"  # nuua-check가 이 시각 전에 연 Claude Code 창(새 설정을 못 읽음)을 찾음

step 7 "회의 녹음 받아쓰기(transcribe) — 모델 1.6GB라 가장 오래 걸려요"
# 내 맥 안에서만 도는 음성 인식(whisper.cpp + large-v3-turbo). 녹음이 밖으로 나가지 않음.
W="$HOME/tools/whisper.cpp"
if [ ! -x "$W/build/bin/whisper-cli" ]; then
  CMAKE=$(command -v cmake || echo "$HOME/Library/Python/3.9/bin/cmake")
  [ -x "$CMAKE" ] || { /usr/bin/python3 -m pip install --user -q cmake >/dev/null 2>&1; CMAKE="$HOME/Library/Python/3.9/bin/cmake"; }
  if [ ! -d "$W" ]; then
    mkdir -p "$HOME/tools" && curl -fsSL https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.9.5.tar.gz | tar -xz -C "$HOME/tools" \
      && mv "$HOME/tools/whisper.cpp-1.9.5" "$W"
  fi
  printf '  … 음성 인식 프로그램 만드는 중(1분 안팎)\n'
  ( cd "$W" && "$CMAKE" -B build -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && "$CMAKE" --build build -j --config Release --target whisper-cli >/dev/null 2>&1 ) \
    && ok "whisper.cpp" || warn "whisper.cpp 빌드 실패(받아쓰기만 안 돼요)"
else ok "whisper.cpp(이미 있음)"; fi
M="$W/models/ggml-large-v3-turbo.bin"
if [ ! -s "$M" ] || [ "$(stat -f%z "$M")" -lt 1600000000 ]; then
  printf '  … 음성 인식 모델 내려받는 중(1.6GB, 인터넷에 따라 3~10분)\n'
  mkdir -p "$W/models" && curl -fL -# -C - -o "$M" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin \
    && ok "모델" || warn "받아쓰기 모델 받기 실패 → 이 설치를 다시 실행하면 이어서 받아요"
else ok "모델(이미 있음)"; fi
cp "$KIT/bin/transcribe" "$HOME/.local/bin/transcribe" && chmod +x "$HOME/.local/bin/transcribe" && ok "transcribe 명령" || warn "transcribe 명령 복사 실패"

if [ ${#FAILS[@]} -eq 0 ]; then
  printf '\n✅ 설치 끝! 설치 페이지로 돌아가 4단계(회사 계정 연결)를 해 주세요.\n   막히면 새 터미널에 nuua-check → 무엇이 문제인지 알려 줘요.\n'
else
  printf '\n⚠ 설치는 끝났지만 %s개가 실패했어요:\n' "${#FAILS[@]}"
  for f in "${FAILS[@]}"; do printf '   ! %s\n' "$f"; done
  printf '   → 이 설치를 한 번 더 실행하면 실패한 것만 다시 해요. 그래도 남으면 이 화면을 캡처해서 설치 담당자에게 보내 주세요.\n   나머지는 설치 페이지 4단계(회사 계정 연결)부터 이어서 하면 돼요.\n'
  exit 1
fi
