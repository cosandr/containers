#!/bin/sh

if [ "$ENABLE_UFW" = "true" ]; then
    ufw allow 5351/udp  # NAT-PMP
    ufw allow 1900/udp  # UPnP
fi
