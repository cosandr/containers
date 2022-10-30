#!/usr/bin/env sh

chown -R "${PUID:-1000}:${PGID:-1000}" /usr/share/nginx/html
