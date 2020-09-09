#!/bin/bash

source ./env.sh

base_dir="$(pwd -P)"

declare -a containers=("cloudflare-ddns" "jellyfin" "mrbot" "nextcloud" "plex" "syncthing" "twitch")

for name in "${containers[@]}"; do
    svc_path="$base_dir/containers/$name"
    if [[ ! -f "$svc_path/docker-compose.yml" ]]; then
        echo "$name no compose file"
        continue
    fi
    cd "$svc_path" || continue
    if ! grep -P '^\s+build:.*' docker-compose.yml; then
        docker-compose pull
    else
        docker-compose build --pull
    fi
    docker-compose up -d
done

# Run VPN
cd "$base_dir/containers/vpn" || exit 1
declare -a services=("vpn" "firefox" "sonarr")
docker-compose pull ${services[*]}
docker-compose up -d ${services[*]}
