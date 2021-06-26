#!/bin/bash

if [[ ! -f env.sh ]]; then
    echo "No env.sh file found, cannot run"
    exit 1
fi

# TODO: parse files in Python and build/push based on services, not compose files.

# shellcheck disable=SC1091
source env.sh &>/dev/null || exit 1

BUILD=${BUILD:-1}
DRY_RUN=${DRY_RUN:-0}

ex_code=0

dc() {
    local cmd="docker-compose $*"
    if [[ $DRY_RUN -eq 0 ]]; then
        eval "$cmd"
        local ret=$?
        ex_code=$(( ret > ex_code ? ret : ex_code ))
        return $ret
    else
        echo "DRY_RUN: $cmd"
    fi
}

for f in */docker-compose*.{yml,yaml}; do
    name=$(dirname "$f")
    # Check if it needs to be skipped
    if [[ -f $name/.no-auto-build ]]; then
        echo "skip $name: disabled"
        continue
    fi
    # Check if there's a build defined
    if ! grep -qP '^\s+build:.*' "$f"; then
        echo "skip $name: no build defined" >&2
        continue
    fi
    # Check if it's using my registry
    if ! tag=$(grep -oP '^\s+image:\s*\$\{C_REGISTRY_BASE.*\}(/|:)\K(.*)' "$f"); then
        echo "skip $name: not using defined registry" >&2
        continue
    fi
    echo "build $tag"
    if ! dc -f "$f" build --pull; then
        echo "building $tag failed"
        continue
    fi
    echo "push $tag"
    dc -f "$f" push
done

exit "$ex_code"
