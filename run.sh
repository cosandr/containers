#!/bin/bash

set -o pipefail -o noclobber -o nounset

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "'getopt --test' failed in this environment."
    exit 1
fi

OPTIONS=h,a,n,c:,e:,p:
LONGOPTS=help,all,dry-run,config-file:,env-file:,preset:,name:,no-build,no-pull,no-busy,no-swarm

! PARSED=$(getopt --options=${OPTIONS} --longoptions=${LONGOPTS} --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "${PARSED}"

_swarm_default=0
if docker node ls &>/dev/null; then
    _swarm_default=1
fi

_preset_default=""
_preset_help=""
if [[ -f .preset ]]; then
    _preset_default=$(<.preset)
    _preset_help="[$_preset_default] (.preset)"
fi

ex_code=0
base_dir="$(pwd -P)"
BUILD=${BUILD:-1}
BUSY=${BUSY:-1}
DRY_RUN=${DRY_RUN:-0}
NAMES=${NAMES:-}
PRESET=${PRESET:-$_preset_default}
PULL=${PULL:-1}
RUN_ALL=${RUN_ALL:-0}
SWARM=${SWARM:-$_swarm_default}

_config_default="config.sh"
_env_default="env.sh"
if [[ -n "$PRESET" ]]; then
    [[ -f "config.$PRESET.sh" ]] && _config_default="config.$PRESET.sh"
    [[ -f "env.$PRESET.sh" ]] && _env_default="env.$PRESET.sh"
fi

CONFIG_FILE=${CONFIG_FILE:-$_config_default}
ENV_FILE=${ENV_FILE:-$_env_default}

unset _swarm_default _preset_default _config_default _env_default
# key: folder name
# value: space seperated list of services, starts all if empty
declare -A containers=()

print_help() {
cat <<-END
Usage $0: COMMAND [OPTIONS]

Commands:
up                      Start containers
push                    Build and push local images

Options:
-h    --help            Show this message
-a    --all             Run all docker-compose files
-n    --dry-run         Don't make changes, print commands that would be run
-c    --config-file     Path to config file [$CONFIG_FILE]
-e    --env-file        Path to env file [$ENV_FILE]
-p    --preset          Preset name to use $_preset_help
      --name            Provide comma seperated container names to operate on
      --no-build        Don't build images
      --no-pull         Don't pull updated images
      --no-busy         Ignore busy containers
      --no-swarm        Force Docker Compose even if Swarm is available
END
}

while true; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -a|--all)
            RUN_ALL=1
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -c|--config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -e|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -p|--preset)
            PRESET="$2"
            shift 2
            _preset_help="[$PRESET]"
            [[ -f "config.$PRESET.sh" ]] && CONFIG_FILE="config.$PRESET.sh" || CONFIG_FILE="config.sh"
            [[ -f "env.$PRESET.sh" ]] && ENV_FILE="env.$PRESET.sh" || ENV_FILE="env.sh"
            ;;
        --name)
            NAMES="$2"
            shift 2
            ;;
        --no-build)
            BUILD=0
            shift
            ;;
        --no-pull)
            PULL=0
            shift
            ;;
        --no-busy)
            BUSY=0
            shift
            ;;
        --no-swarm)
            SWARM=0
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

unset _preset_help

if [[ $# -ne 1 ]]; then
    echo "$0: A command is required."
    exit 4
fi

trap 'exit $ex_code' EXIT

if [[ ! -f $ENV_FILE ]]; then
    echo "Env file '$ENV_FILE' not found"
    exit 1
fi

# shellcheck source=env.sh disable=SC1091
source "$ENV_FILE" || exit 1

if [[ -f $CONFIG_FILE ]]; then
    # shellcheck source=config.sh
    source "$CONFIG_FILE"
    echo "Read config file '$CONFIG_FILE'"
fi

run_cmd() {
    if [[ $DRY_RUN -eq 0 ]]; then
        eval "$*"
        local ret=$?
        ex_code=$(( ret > ex_code ? ret : ex_code ))
        return $ret
    else
        echo "DRY RUN: $*"
    fi
}

find_all_containers() {
    local name
    # Reset array
    declare -gA containers=()
    for file in */docker-compose.{yml,yaml}; do
        name="$(dirname "$file")"
        name="${name/#\.\//}"
        echo "Found '$name'"
        containers["$name"]=""
    done
}

run_common() {
    if [[ $RUN_ALL -eq 1 ]]; then
        find_all_containers
    elif [[ -n $NAMES ]]; then
        # Reset array
        declare -gA containers=()
        IFS=',' read -ra TMP_NAMES <<< "$NAMES"
        for n in "${TMP_NAMES[@]}"; do
            containers["$n"]=""
        done
    fi
    if [[ ${#containers[@]} -eq 0 ]]; then
        echo "No containers found or configured"
        ex_code=1
        exit
    fi
}

find_compose_file() {
    if [[ -n $PRESET && -f "$svc_path/docker-compose.$PRESET.yml" ]]; then
        compose_file="docker-compose.$PRESET.yml"
    elif [[ -n $PRESET && -f "$svc_path/docker-compose.$PRESET.yaml" ]]; then
        compose_file="docker-compose.$PRESET.yaml"
    elif [[ -f $svc_path/docker-compose.yml ]]; then
        compose_file="docker-compose.yml"
    elif [[ -f $svc_path/docker-compose.yaml ]]; then
        compose_file="docker-compose.yaml"
    else
        echo "$name no compose file"
        return 1
    fi
}

check_busy() {
    # Check for busy file
    if [[ $BUSY -eq 1 && -f ./data/busy ]]; then
        echo "$1 is busy, skipping"
        return 0
    fi
    if [[ $BUSY -eq 1 && -f ./data/.lock ]]; then
        echo "$1 is locked, skipping"
        return 0
    fi
    return 1
}

run_up() {
    # Disable word-splitting warning, it's what we want
    # shellcheck disable=SC2086
    for name in "${!containers[@]}"; do
        svc_path="$base_dir/$name"
        if ! cd "$svc_path"; then
            ex_code=2
            continue
        fi
        if ! find_compose_file; then
            ex_code=2
            continue
        fi
        if check_busy "$name"; then
            continue
        fi
        if ! grep -qP '^\s+build:.*' "$compose_file"; then
            if [[ $PULL -eq 1 ]]; then
                run_cmd docker compose -f "$compose_file" pull ${containers[$name]}
            fi
        elif [[ $BUILD -eq 1 ]]; then
            if [[ $PULL -eq 1 ]]; then
                run_cmd docker compose -f "$compose_file" build --pull ${containers[$name]}
            else
                run_cmd docker compose -f "$compose_file" build ${containers[$name]}
            fi
        fi
        if [[ $SWARM -eq 1 ]]; then
            if [[ -f .env ]]; then
                # https://github.com/moby/moby/issues/29133#issuecomment-278198683
                # docker compose config fails for multiple reasons, missing version and wrong type for ports (wants int, gets str)
                run_cmd env "$(grep '^[A-Z]' .env | xargs -d '\n')" docker stack deploy --with-registry-auth --compose-file "$compose_file" "$name"
                # (set -a && source .env && set +a; run_cmd docker stack deploy -c "$compose_file" "$name")
            else
                run_cmd docker stack deploy --with-registry-auth --compose-file "$compose_file" "$name"
            fi
        else
            run_cmd docker compose -f "$compose_file" up -d ${containers[$name]}
        fi

    done
}

run_push() {
    if [[ -z $C_REGISTRY_BASE ]]; then
        echo "C_REGISTRY_BASE must be defined"
        ex_code=1
        exit
    fi

    for name in "${!containers[@]}"; do
        svc_path="$base_dir/$name"
        if ! cd "$svc_path"; then
            ex_code=2
            continue
        fi

        if ! find_compose_file; then
            ex_code=2
            continue
        fi

        # Check if it needs to be skipped
        if [[ -f ./.no-auto-build ]]; then
            echo "skip $name: disabled"
            continue
        fi
        # Check if there's a build defined
        if ! grep -qP '^\s+build:.*' "$compose_file"; then
            echo "skip $name: no build defined" >&2
            continue
        fi
        # Check if it's using my registry
        if ! tag=$(grep -oP '^\s+image:\s*\$\{C_REGISTRY_BASE.*\}(/|:)\K(.*)' "$compose_file"); then
            echo "skip $name: not using defined registry" >&2
            continue
        fi
        echo "build $tag"
        if [[ $BUILD -eq 1 ]]; then
            if [[ $PULL -eq 1 ]]; then
                run_cmd docker compose -f "$compose_file" build --pull
            else
                run_cmd docker compose -f "$compose_file" build
            fi
        fi
        echo "push $tag"
        run_cmd docker compose -f "$compose_file" push
    done
}

# Loosely based on https://github.com/containrrr/shepherd/blob/master/shepherd
run_update_swarm() {
    if ! command -v skopeo >/dev/null; then
        echo "skopeo is required"
        exit 1
    fi
    local name stack_name svc_path image image_with_digest digest
    for name in $(IFS=$'\n' docker service ls --quiet --format '{{.Name}}'); do
        stack_name="$(docker service inspect "$name" -f '{{index .Spec.Labels "com.docker.stack.namespace"}}')"
        svc_path="$base_dir/$stack_name"
        if ! cd "$svc_path"; then
            ex_code=2
            continue
        fi
        if check_busy "$stack_name"; then
            continue
        fi

        image_with_digest="$(docker service inspect "$name" -f '{{.Spec.TaskTemplate.ContainerSpec.Image}}')"
        image=$(echo "$image_with_digest" | cut -d@ -f1)
        if [[ -z $image ]]; then
            echo "skip $name: Cannot determine image"
            ex_code=2
            continue
        fi
        # Try to find current digest
        digest="$(docker service ps "$name" --no-trunc --format '{{.Image}}' -f desired-state=running | head -n1 | cut -d@ -f2)"
        if [[ -n $digest ]]; then
            new_digest="$(skopeo inspect "docker://$image" --no-tags -f '{{.Digest}}')"
            if [[ "$digest" == "$new_digest" ]]; then
                echo "skip $name: No update required"
                continue
            fi
        fi
        run_cmd docker service update "$name" --force --with-registry-auth --image "$image"
    done
}

case "$1" in
    up)
        run_common
        run_up
        ;;
    push)
        run_common
        run_push
        ;;
    update-swarm)
        run_common
        run_update_swarm
        ;;
    *)
        echo "Unrecognized command: $1"
        print_help
        ex_code=1
        exit
        ;;
esac
