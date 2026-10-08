"""settings-snippet.json의 hooks·statusLine을 ~/.claude/settings.json에 합친다. 기존 값은 지우지 않고, 같은 명령이 이미 있으면 건너뛴다."""
import json, pathlib, shutil, sys, time

snip = json.loads(pathlib.Path(sys.argv[1]).read_text())
p = pathlib.Path.home() / '.claude' / 'settings.json'
cur = json.loads(p.read_text()) if p.exists() else {}
if p.exists():
    shutil.copy(p, p.with_name(f'settings.json.bak_{time.strftime("%m%d_%H%M")}'))
hooks = cur.setdefault('hooks', {})
for event, groups in snip['hooks'].items():
    have = {h['command'] for g in hooks.get(event, []) for h in g.get('hooks', [])}
    for g in groups:
        if not any(h['command'] in have for h in g['hooks']):
            hooks.setdefault(event, []).append(g)
cur.setdefault('statusLine', snip['statusLine'])  # 이미 상태줄이 있으면 그대로 둔다
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(cur, ensure_ascii=False, indent=2))
