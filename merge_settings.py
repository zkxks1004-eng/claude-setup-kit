"""settings-snippet.json의 hooks·statusLine을 ~/.claude/settings.json에 합친다. 기존 값은 지우지 않고, 같은 명령이 이미 있으면 건너뛴다.
두 번째 인자로 env JSON 파일을 주면 settings.json의 env에 덮어 합친다(다른 env 키는 그대로).
두 번째 인자가 --no-telemetry면 설치가 넣은 사용 현황 보내기 env(누아 주소로 가는 것만)를 뺀다."""
import json, pathlib, shutil, sys, time

snip = json.loads(pathlib.Path(sys.argv[1]).read_text())
p = pathlib.Path.home() / '.claude' / 'settings.json'
cur = json.loads(p.read_text()) if p.exists() else {}
bak = p.with_name(f'settings.json.bak_{time.strftime("%m%d_%H%M")}')
if p.exists() and not bak.exists():  # 같은 분에 두 번 돌아도 처음 백업(원본)을 지키게
    shutil.copy(p, bak)
hooks = cur.setdefault('hooks', {})
for event, groups in snip['hooks'].items():
    have = {h.get('command') for g in hooks.get(event, []) for h in g.get('hooks', [])}
    for g in groups:
        if not any(h['command'] in have for h in g['hooks']):
            hooks.setdefault(event, []).append(g)
cur.setdefault('statusLine', snip['statusLine'])  # 이미 상태줄이 있으면 그대로 둔다
if len(sys.argv) > 2:
    env = cur['env'] = cur['env'] if isinstance(cur.get('env'), dict) else {}  # 없거나 null 등 → 빈 env
    if sys.argv[2] == '--no-telemetry':
        mine = 'nuua' in str(env.get('OTEL_EXPORTER_OTLP_ENDPOINT', '')) or 'nuua.kit=' in str(env.get('OTEL_RESOURCE_ATTRIBUTES', ''))
        if mine:  # 키트가 넣은 것만 뺀다. 내가 따로 켠 다른 OTEL 설정은 건드리지 않음
            for k in [k for k in env if k.startswith('OTEL_') or k in ('CLAUDE_CODE_ENABLE_TELEMETRY', 'CLAUDE_CODE_ENHANCED_TELEMETRY_BETA')]:
                del env[k]
    else:
        env.update(json.loads(pathlib.Path(sys.argv[2]).read_text()))
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(cur, ensure_ascii=False, indent=2))
