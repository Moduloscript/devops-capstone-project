import json, sys

pr = json.load(sys.stdin)
trs = pr.get('status', {}).get('taskRuns', {})
for k, v in trs.items():
    name = k.split('/')[-1]
    cs = v.get('status', {}).get('conditions', [{}])[0]
    print(f'=== {name} ===')
    print(f'  Reason: {cs.get("reason", "?")}')
    print(f'  Status: {cs.get("status", "?")}')
    print(f'  Message: {cs.get("message", "")[:500]}')
    print()
