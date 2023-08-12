#!/bin/bash

# https://github.com/niklasberglund/transmission-rpc-bash/blob/master/transmission-rpc.sh
# https://www.reddit.com/r/ProtonVPN/comments/10owypt/successful_port_forward_on_debian_wdietpi_using/

RPC_URL="http://localhost:$TRANSMISSION_RPC_PORT/transmission/rpc/"

PREVIOUS_PORT=""

while true; do
    SESSION_HEADER=$(curl -s --anyauth "$RPC_URL" | sed 's/.*<code>//g;s/<\/code>.*//g')
    CURRENT_PORT=$(curl -s -XPOST -H "$SESSION_HEADER" "$RPC_URL" -d '{"method": "session-get", "arguments": {"fields": ["peer-port"]}}' | jq '.arguments."peer-port"')
    if [[ -z $CURRENT_PORT ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Cannot determine current port"
        # Shorter sleep, transmission probably just isn't ready
        sleep 10
        continue
    fi
    if [[ "$CURRENT_PORT" = "$PREVIOUS_PORT" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') No change required"
    else
        if [[ -n $PREVIOUS_PORT ]] && ufw delete allow "$PREVIOUS_PORT"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') Removed $PREVIOUS_PORT from ufw"
        fi
        if ufw allow "$CURRENT_PORT"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') Added $CURRENT_PORT to ufw"
        fi
    fi
    sleep 300
done
