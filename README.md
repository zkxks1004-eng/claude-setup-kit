# 누아 Claude Code 설정 키트 (맥)

**공통 + 팀별 묶음**으로 플러그인·MCP·훅·도구와 누아 전용 스킬을 설치해요. 팀에 필요한 것만 깔아요. 기능이 많을수록 Claude가 매 대화마다 그 설명을 다 읽고 시작해서 느려지고 헷갈리거든요. **비밀값·토큰은 들어 있지 않아요.** 로그인은 각자 합니다.

설치 안내 페이지: https://nuua-claude-setup.zkxks1004.workers.dev

## 1. 설치 (20분 안팎 — 받아쓰기 모델 1.6GB 포함)

> ⚠ **Claude에게 "이거 설치해 줘"라고 시키지 마세요.** Claude가 자기 설정을 스스로 바꾸는 건 안전장치가 막아요. **터미널에 직접** 붙여 넣으세요.

```bash
curl -fsSL https://raw.githubusercontent.com/zkxks1004-eng/claude-setup-kit/main/bootstrap.sh | bash
```

처음에 팀 번호를 물어요(`1` 사업개발 · `2` 서비스기획 · `3` 개발(기술연구소) · `0` 공통만, 여러 개면 `1 2`처럼 띄어서). 미리 정하려면 `… | NUUA_ROLE="planning" bash`처럼 `bash` 바로 앞에 붙여요(맨 앞 `curl` 앞에 붙이면 전달되지 않아요).

먼저 있어야 하는 것: Claude Code(`claude` 명령). 맥 개발 도구(git·python3)가 없으면 설치 창을 띄우고 끝날 때까지 기다렸다가 이어서 해요. Node가 없으면 `~/.local/node`에 공식 LTS를 깔아요(관리자 비밀번호 필요 없음).

## 2. 무엇이 깔리나

| 묶음 | 플러그인 | MCP·도구 |
|---|---|---|
| **공통** | nuua-common(사내 맥락 스킬 + 컨플루언스 덮어쓰기 전 확인 훅) · **atlassian 공식**(연결 + 스킬 6개) · skill-creator(반복 업무→내 스킬) · claude-md-management(지침 정리) · cc-safety-net(위험 명령 차단) | markitdown · uv · 상태줄 · 알림·현재 시각 훅 · 회의 녹음 받아쓰기(transcribe) |
| 사업개발 | notion · figma · duckdb-skills · firecrawl | clasp · duckdb |
| 서비스기획 | **nuua-planning**(회의록 · 주간 취합 · 지라 요청 정리) · figma | |
| 개발 | superpowers · feature-dev · code-review · pr-review-toolkit · commit-commands · context7 · playwright · frontend-design | |

**고른 기준**: 처음 쓰는 사람도 바로 효과가 나는 것, 그리고 매 대화에 얹히는 설명과 연결이 적은 것.
- knowledge-work-plugins(productivity·data·product-management·operations 등)는 뺐어요. 쓰지 않는 외부 서비스 연결(slack·asana·amplitude 등)을 8~16개씩 달고 와서 로그인 요청이 쌓이고, atlassian·notion이 세 번씩 떠요.
- atlassian·notion·figma 연결은 플러그인 안에 들어 있어요. 예전 키트나 claude.ai에서 따로 넣은 연결은 그대로 남아 `/mcp`에 두 번 보일 수 있어요. 이미 로그인된 쪽을 쓰면 되고, `nuua-check`가 같은 주소면 알려 줘요.
- 엑셀·워드·PPT·PDF 스킬은 claude.ai 계정의 기본 스킬로 따라와요.

### 누아 전용 스킬 (`plugins/`, 이 저장소가 플러그인 마켓 `nuua`)

| 스킬 | 이럴 때 |
|---|---|
| `nuua-context` | 사내 Confluence·Jira 작업 전체: 스페이스·프로젝트 키, 쓰기 규칙, 조회를 가볍게 하는 법 |
| `nst-meeting-notes` | "회의록 정리해줘": 팀 형식으로 정리하고, N차 정례 회의면 지난 차수의 다음 액션을 불러와요 |
| `nst-weekly` | "이번 주 내 진행 사항": "N월 N주" 내 칸 초안(붙여 넣기용) |
| `jira-request` | "지라 올려줘": 중복 검색 → 프로젝트·담당 영역 제안 → 확인 후 생성 |

공개 저장소라 스킬에는 사람 이름을 넣지 않아요. 담당자는 실행할 때 Confluence의 컨택 포인트 페이지를 읽어서 정해요.

## 3. 로그인 (각자 1번)

claude.ai 커넥터로 이미 연결된 도구(atlassian 등)는 `/mcp` 목록에 두 번 보일 수 있어요. 이미 로그인된 쪽을 쓰면 되고, 새로 추가된 쪽은 로그인하지 않아도 괜찮아요.

| 대상 | 방법 |
|---|---|
| atlassian · figma · notion | Claude Code에서 `/mcp` → `plugin:atlassian:atlassian` 등 선택 → 회사 계정으로 로그인 |
| firecrawl | `firecrawl login` (무료 계정, 월 크레딧 있음) |
| clasp | `clasp login` (Apps Script 쓸 때만) |

## 4. 확인

```bash
nuua-check                # 로그인 메일·등록·사용 현황 연결·연결 도구·Node까지 한 번에(✓/✕ + 고치는 방법)
```

Claude Code를 새로 열고 아무 질문이나 하면 "현재 시각"이 붙고, 답이 끝나거나 권한을 물을 때·한도나 로그인 오류로 멈출 때 맥 알림이 떠요. 내 사용 현황은 `/usage`·`/insights`로 볼 수 있어요. 설치 키트에 새 판이 나오거나 Node가 없으면 Claude Code를 열 때 화면에 한 줄로 알려 줘요(6시간에 한 번 확인).

## 5. 업데이트

위 한 줄 설치를 다시 실행하면 돼요. 누아 스킬도 설치할 때마다 최신으로 받아요.

## 참고

- 기존 `~/.claude/settings.json`은 지우지 않고 합쳐요. 처음 원본은 `settings.json.nuua-first`, 매번 합치기 직전 것은 `settings.json.nuua-last`로 남아요. 직접 넣은 연결 도구·훅은 건드리지 않고, 직접 넣은 수집 주소(`OTEL_EXPORTER_OTLP_ENDPOINT`)가 있으면 수집 설정도 그대로 두고, 꺼 둔 플러그인도 다시 켜지 않아요.
- 사용 현황 보내기 끄기: `touch ~/.claude/.nuua-no-telemetry && /usr/bin/python3 ~/claude-setup-kit/merge_settings.py ~/claude-setup-kit/settings-snippet.json --no-telemetry`(다음 설치에서도 계속 꺼짐) · 다시 켜기: `rm ~/.claude/.nuua-no-telemetry` 후 설치를 다시.
- 예전 키트(18개 전부)로 설치했다면, 팀에 없는 플러그인은 `claude plugin disable 이름@마켓`으로 꺼 두면 가벼워져요(다시 켜기: `enable`).
- 맥 알림이 안 뜨면: 시스템 설정 → 알림 → "스크립트 편집기"(또는 터미널) 알림 허용.
