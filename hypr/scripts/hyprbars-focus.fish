#!/usr/bin/env fish

set HYPRLAND_INSTANCE $HYPRLAND_INSTANCE_SIGNATURE
set WS $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE

# Set initial state
set ADDR (hyprctl activewindow -j | jq -r '.address')
hyprctl reload config-only
hyprctl keyword windowrule 'hyprbars:bar_color rgba(13131700)' 'class:.*'
if test -n "$ADDR" && test "$ADDR" != null
    hyprctl keyword windowrule 'hyprbars:bar_color rgba(1313178C)' "address:0x$ADDR"
end

# Listen for focus changes
socat -U - UNIX-CONNECT:$WS/.socket2.sock | while read -l event
    switch $event
        case 'activewindowv2>>*'
            set addr (string split '>>' $event)[2]
            if test -n "$addr" && test "$addr" != ' '
                hyprctl reload config-only
                hyprctl keyword windowrule 'hyprbars:bar_color rgba(13131700)' 'class:.*'
                hyprctl keyword windowrule 'hyprbars:bar_color rgba(1313178C)' "address:0x$addr"
            end
    end
end
