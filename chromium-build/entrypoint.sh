#!/bin/bash

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Change user and group ID
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc
# Ensure proper home directory permissions
chown -R abc:abc /home/abc

# Run command as abc
sudo -u abc /bin/sh -c "$@"
