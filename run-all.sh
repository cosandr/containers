#!/bin/bash

if [[ ! -f env.sh ]]; then
    echo "No env.sh file found, cannot run"
    exit 1
fi

# shellcheck disable=SC1091
source env.sh || exit 1

base_dir="$(pwd -P)"
BUILD=${BUILD:-1}
PULL=${PULL:-1}
BUSY=${BUSY:-1}

# key: folder name
# value: space seperated list of services, starts all if empty
declare -A containers=(
    ["cloudflare-ddns"]=""
    ["jellyfin"]=""
    ["mrbot"]=""
    ["nextcloud"]=""
    ["plex"]=""
    ["syncthing"]=""
    ["standard-notes"]=""
    ["twitch"]=""
    ["gitlab"]=""
    ["vpn"]="vpn firefox sonarr"
)

ex_code=0
# Disable word-splitting warning, it's what we want
# shellcheck disable=SC2086
for name in "${!containers[@]}"; do
    svc_path="$base_dir/$name"
    if [[ ! -f "$svc_path/docker-compose.yml" ]]; then
        echo "$name no compose file"
        ex_code=2
        continue
    fi
    if ! cd "$svc_path"; then
        ex_code=2
        continue
    fi
    # Check for busy file
    if [[ $BUSY -eq 1 && -f ./data/busy ]]; then
        echo "$name is busy, skipping"
        continue
    fi
    if ! grep -qP '^\s+build:.*' docker-compose.yml; then
        if [[ $PULL -eq 1 ]]; then
            docker-compose pull ${containers[$name]}
            ex_code=$(( $? > ex_code ? $? : ex_code ))
        fi
    elif [[ $BUILD -eq 1 ]]; then
        if [[ $PULL -eq 1 ]]; then
            docker-compose build --pull ${containers[$name]}
            ex_code=$(( $? > ex_code ? $? : ex_code ))
        else
            docker-compose build ${containers[$name]}
            ex_code=$(( $? > ex_code ? $? : ex_code ))
        fi
    fi
    docker-compose up -d ${containers[$name]}
    ex_code=$(( $? > ex_code ? $? : ex_code ))
done

docker container prune --force
docker network prune --force

exit $ex_code
