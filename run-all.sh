#!/bin/bash

if [[ ! -f env.sh ]]; then
    echo "No env.sh file found, cannot run"
    exit 1
fi

# shellcheck disable=SC1091
source env.sh

base_dir="$(pwd -P)"
BUILD=${BUILD:-1}
PULL=${PULL:-1}

# key: folder name
# value: space seperated list of services, starts all if empty
declare -A containers=(
    ["cloudflare-ddns"]=""
    ["jellyfin"]=""
    ["mrbot"]=""
    ["nextcloud"]=""
    ["plex"]=""
    ["syncthing"]=""
    ["twitch"]=""
    ["vpn"]="vpn firefox sonarr"
)

# Disable word-splitting warning, it's what we want
# shellcheck disable=SC2086
for name in "${!containers[@]}"; do
    svc_path="$base_dir/$name"
    if [[ ! -f "$svc_path/docker-compose.yml" ]]; then
        echo "$name no compose file"
        continue
    fi
    cd "$svc_path" || continue
    if ! grep -qP '^\s+build:.*' docker-compose.yml; then
        [[ $PULL -eq 1 ]] && docker-compose pull ${containers[$name]}
    elif [[ $BUILD -eq 1 ]]; then
        if [[ $PULL -eq 1 ]]; then
            docker-compose build --pull ${containers[$name]}
        else
            docker-compose build ${containers[$name]}
        fi
    fi
    docker-compose up -d ${containers[$name]}
done
