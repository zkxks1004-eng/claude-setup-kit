"""settings-snippet.json의 hooks·statusLine을 ~/.claude/settings.json에 합친다. 기존 값은 지우지 않고, 같은 명령이 이미 있으면 건너뛴다.
두 번째 인자로 env JSON 파일을 주면 settings.json의 env에 덮어 합친다(다른 env 키는 그대로).
  단, 내가 따로 설정한 OTEL 보내기(누아가 아닌 주소)가 있으면 건드리지 않고 종료 코드 3.
두 번째 인자가 --no-telemetry면 설치가 넣은 사용 현황 보내기 env 키만 뺀다(내가 따로 넣은 OTEL_* 는 그대로).
백업: 처음 합치기 전 원본은 settings.json.nuua-first(한 번만), 매번 합치기 직전 것은 settings.json.nuua-last(덮어씀)."""
import json, pathlib, shutil, sys

# 설치(install.sh 6단계)가 넣는 env 키 — 끌 때 이것만 뺀다
KIT_ENV = {'CLAUDE_CODE_ENABLE_TELEMETRY', 'OTEL_METRICS_EXPORTER', 'OTEL_LOGS_EXPORTER', 'OTEL_EXPORTER_OTLP_PROTOCOL',
           'OTEL_EXPORTER_OTLP_ENDPOINT', 'OTEL_EXPORTER_OTLP_HEADERS', 'OTEL_METRIC_EXPORT_INTERVAL', 'OTEL_LOGS_EXPORT_INTERVAL',
           'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', 'OTEL_RESOURCE_ATTRIBUTES', 'OTEL_LOG_USER_PROMPTS', 'OTEL_LOG_TOOL_DETAILS',
           'OTEL_LOG_ASSISTANT_RESPONSES', 'OTEL_LOG_TOOL_CONTENT', 'OTEL_LOG_RAW_API_BODIES', 'CLAUDE_CODE_ENHANCED_TELEMETRY_BETA',
           'OTEL_TRACES_EXPORTER'}
# 예전 키트가 넣은 훅 명령(jq를 써서 macOS 14에선 조용히 안 됨) → 새 명령으로 바꾸려고 먼저 뺀다
OLD_HOOKS = {
    # 10/14 전 알림 명령(Notification·Stop 같은 명령) → Notification은 idle_prompt를 건너뛰는 새 명령으로 바뀜. Stop은 같은 명령을 다시 넣음
    '/usr/bin/python3 -c \'import json,os,subprocess,sys\nd=json.load(sys.stdin)\nsubprocess.run(["osascript","-e","on run a","-e","display notification (item 2 of a) with title (item 1 of a) sound name \\"Glass\\"","-e","end run","Claude · "+os.path.basename(d.get("cwd") or "?"),d.get("message") or "작업 끝 — 입력 대기"])\' 2>/dev/null || true',
    "jq -n --arg t \"$(date '+%Y-%m-%d(%a) %H:%M %Z')\" '{hookSpecificOutput:{hookEventName:\"UserPromptSubmit\",additionalContext:(\"현재 시각: \" + $t)}}' 2>/dev/null || true",
    "i=$(cat); p=$(printf %s \"$i\" | jq -r \".cwd // \\\"?\\\"\"); m=$(printf %s \"$i\" | jq -r \".message // \\\"작업 끝 — 입력 대기\\\"\"); osascript -e \"on run a\" -e \"display notification (item 2 of a) with title (item 1 of a) sound name \\\"Glass\\\"\" -e \"end run\" \"Claude · ${p##*/}\" \"$m\" 2>/dev/null || true",
}

snip = json.loads(pathlib.Path(sys.argv[1]).read_text())
p = pathlib.Path.home() / '.claude' / 'settings.json'
cur = json.loads(p.read_text()) if p.exists() and p.read_text().strip() else {}
if not isinstance(cur, dict):
    sys.exit('settings.json 맨 바깥이 { } 가 아니에요')

hooks = cur['hooks'] if isinstance(cur.get('hooks'), dict) else {}
for event in list(hooks):
    groups = [dict(g, hooks=[h for h in g.get('hooks', []) if h.get('command') not in OLD_HOOKS]) for g in hooks[event] or []]
    hooks[event] = [g for g in groups if g['hooks']]
for event, groups in snip['hooks'].items():
    have = {h.get('command') for g in hooks.get(event, []) for h in g.get('hooks', [])}
    for g in groups:
        if not any(h['command'] in have for h in g['hooks']):
            hooks.setdefault(event, []).append(g)
cur['hooks'] = {k: v for k, v in hooks.items() if v}
cur.setdefault('statusLine', snip['statusLine'])  # 이미 상태줄이 있으면 그대로 둔다

if len(sys.argv) > 2:
    env = cur['env'] = cur['env'] if isinstance(cur.get('env'), dict) else {}  # 없거나 null 등 → 빈 env
    mine = 'nuua' in str(env.get('OTEL_EXPORTER_OTLP_ENDPOINT', '')) or 'nuua.kit=' in str(env.get('OTEL_RESOURCE_ATTRIBUTES', ''))
    if sys.argv[2] == '--no-telemetry':
        if mine:  # 키트가 넣은 것만 뺀다. 내가 따로 켠 다른 OTEL 설정은 건드리지 않음
            for k in KIT_ENV & set(env):
                del env[k]
    else:
        if env.get('OTEL_EXPORTER_OTLP_ENDPOINT') and not mine:
            sys.exit(3)  # 내가 따로 쓰는 수집 주소가 있음 → 덮어쓰지 않음
        env.update(json.loads(pathlib.Path(sys.argv[2]).read_text()))

p.parent.mkdir(parents=True, exist_ok=True)
if p.exists():
    first = p.with_name('settings.json.nuua-first')
    if not first.exists():
        shutil.copy(p, first)
    shutil.copy(p, p.with_name('settings.json.nuua-last'))
p.write_text(json.dumps(cur, ensure_ascii=False, indent=2))
