#!/bin/bash

if [[ "$ENABLE_UFW" = "true" ]]; then
    nohup /scripts/update-ufw.sh &> /config/update-ufw.log &
fi
