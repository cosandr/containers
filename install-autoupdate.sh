#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

unit_name="docker-auto-update"
systemd_path="/etc/systemd/system"

cat <<EOF > "$systemd_path/$unit_name.timer"
[Unit]
Description=Docker auto update timer

[Timer]
Persistent=yes
OnCalendar=*-*-* 05:00:00

[Install]
WantedBy=timers.target
EOF

cat <<EOF > "$systemd_path/$unit_name.service"
[Unit]
Description=Update all external Docker containers
After=network-online.target docker.service
Requires=network-online.target docker.service

[Service]
Type=oneshot
WorkingDirectory=$(pwd -P)
Environment=HOSTNAME=$(hostname)
Environment=BUSY=1
Environment=BUILD=1
Environment=PULL=1
ExecStart=/usr/bin/bash run-all.sh
EOF

systemctl daemon-reload
systemctl cat "$unit_name".{timer,service}
