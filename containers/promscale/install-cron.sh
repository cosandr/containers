#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

install -m 0644 promscale-maintaince.{service,timer} /etc/systemd/system/
systemctl daemon-reload

echo "Enable timer with systemctl enable --now promscale-maintaince.timer"
