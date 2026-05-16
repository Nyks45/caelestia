#!/usr/bin/env bash
DELAY="${1:-300}"
EDGE="${2:-15}"  # px to exclude from screen edges
LAST_X="" TIMER_PID=""

while true; do
    POS=$(hyprctl cursorpos 2>/dev/null | head -1)
    X=$(echo "$POS" | cut -d',' -f1 | tr -d ' ')
    Y=$(echo "$POS" | cut -d',' -f2 | tr -d ' ')

    # Skip shell border edges (left, right, top, bottom)
    if [ "$X" -le "$EDGE" ] || [ "$X" -ge $((2560 - EDGE)) ] || \
       [ "$Y" -le "$EDGE" ] || [ "$Y" -ge $((1440 - EDGE)) ]; then
        LAST_X="$X"; LAST_Y="$Y"
        sleep 0.05
        continue
    fi

    if [ "$X" != "$LAST_X" ] || [ "$Y" != "$LAST_Y" ]; then
        LAST_X="$X"; LAST_Y="$Y"
        kill "$TIMER_PID" 2>/dev/null
        (
            sleep "$(echo "scale=3; $DELAY/1000" | bc 2>/dev/null || echo 0.3)"
            ADDR=$(python3 -c "
import json,subprocess,sys
mx,my=$X,$Y
clients=json.loads(subprocess.run(['hyprctl','clients','-j'],capture_output=True,text=True).stdout or '[]')
focused=json.loads(subprocess.run(['hyprctl','activewindow','-j'],capture_output=True,text=True).stdout or '{}')
if not focused or 'at' not in focused: sys.exit()
fwx,fwy=focused['at']; fwsx,fwsy=focused['size']
ox=fwx-(2560-fwsx)//2; oy=fwy-(1440-fwsy)//2
wx,wy=mx+ox,my+oy
for w in clients:
    a=w.get('at',[0,0]); s=w.get('size',[0,0])
    if a[0]<=wx<=a[0]+s[0] and a[1]<=wy<=a[1]+s[1]:
        print(w.get('address',''))
        break
" 2>/dev/null)
            [ -n "$ADDR" ] && hyprctl dispatch focuswindow "address:$ADDR" 2>/dev/null
        ) &
        TIMER_PID=$!
    fi
    sleep 0.05
done
