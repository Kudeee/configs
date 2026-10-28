#!/bin/bash
result=$(timeout 2 intel_gpu_top -J -s 1 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
engines = d.get('engines', {})
for key in engines:
    if 'Render' in key:
        print(int(engines[key]['busy']))
        import sys; sys.exit()
print(0)
" 2>/dev/null)
echo "${result:-0}"
