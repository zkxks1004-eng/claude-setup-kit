# 사업개발팀 Claude Code 설정 키트 (맥)

성훈님 맥과 같은 플러그인·MCP·훅·도구를 한 번에 설치해요. **비밀값·토큰은 들어 있지 않아요** — 로그인은 각자 합니다.

## 1. 설치 (5분)

> ⚠ **Claude에게 "이거 설치해 줘"라고 시키지 마세요.** Claude가 자기 설정을 스스로 바꾸는 건 안전장치가 막아요. 아래 명령을 **터미널에 직접** 붙여 넣거나, Claude Code 입력창에서 맨 앞에 `!`를 붙여 `! bash ~/claude-setup-kit/install.sh`처럼 실행하세요.


```bash
git clone https://github.com/zkxks1004-eng/claude-setup-kit.git ~/claude-setup-kit
bash ~/claude-setup-kit/install.sh
```

먼저 있어야 하는 것: Claude Code(`claude` 명령). 상태줄·firecrawl·clasp는 Node(npm)가 있을 때만 설치돼요 — 없으면 [nodejs.org](https://nodejs.org)에서 LTS 설치 후 다시 실행.

## 2. 무엇이 깔리나

| 종류 | 내용 |
|---|---|
| 플러그인 18개 | superpowers · figma · playwright · firecrawl · chrome-devtools-mcp · context7 · code-review · frontend-design · hookify · claude-md-management · session-report · data · productivity · operations · ui-ux-pro-max · ponytail · cc-safety-net(위험 명령 차단) · duckdb-skills |
| MCP 5개 | figma · atlassian · notion · markitdown(PDF·엑셀→글) · clasp(Apps Script) |
| 훅 3개 | 질문마다 현재 시각 알려 주기 · 작업 끝/입력 대기 때 맥 알림(소리 Glass) |
| 상태줄 | ccstatusline(폴더 · 모델 · 사용량) |
| 도구 | uv · duckdb · gws(구글 시트·드라이브) · firecrawl · clasp |
| 스킬 | gws 5개(시트 읽기·쓰기·드라이브) |

## 3. 로그인 (각자 1번)

claude.ai 커넥터로 이미 연결된 도구(atlassian 등)는 `/mcp` 목록에 두 번 보일 수 있어요. 이미 로그인된 쪽을 쓰면 되고, 새로 추가된 쪽은 로그인하지 않아도 괜찮아요.


| 대상 | 방법 |
|---|---|
| figma · atlassian · notion | Claude Code에서 `/mcp` → 각 서버 선택 → 회사 계정으로 로그인 |
| gws(구글) | `gws auth login` — 구글 클라우드 OAuth 클라이언트가 필요해요. 성훈님께 설정 방법 문의 |
| firecrawl | `firecrawl login` (무료 계정, 월 크레딧 있음) |
| clasp | `clasp login` (Apps Script 쓸 때만) |

## 4. 확인

```bash
claude plugin list        # 플러그인 18개
claude mcp list           # MCP 5개
```

Claude Code를 새로 열고 아무 질문이나 하면 "현재 시각"이 붙고, 답이 끝나면 맥 알림이 떠요.

## 5. 업데이트

```bash
cd ~/claude-setup-kit && git pull && bash install.sh
```

## 참고

- 기존 `~/.claude/settings.json`은 지우지 않고 합쳐요. 합치기 전 파일은 `settings.json.bak_날짜`로 남아요.
- 맥 알림이 안 뜨면: 시스템 설정 → 알림 → "스크립트 편집기"(또는 터미널) 알림 허용.
- gws 자동 설치가 실패하면 [googleworkspace/cli 릴리스](https://github.com/googleworkspace/cli/releases)에서 `…apple-darwin.tar.gz`를 받아 `gws` 파일을 `~/.local/bin`에 넣어 주세요.
