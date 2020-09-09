# Docker containers

Bunch of Dockerfiles and docker-compose files for my containers.

## Environment variables

Recommended to create `env.sh` and source it before running docker-compose commands.
Example:

```sh
#!/bin/bash

# Unset all variables starting with C_
while read -r line; do
    unset "$line"
done <<< "$(env | grep -oP '^C\_\w+')"

export C_UID="$(id -u)"
export C_GID="$(id -g)"
export C_TZ="$(timedatectl --value show -p Timezone)"
export C_DOMAIN="example.com"
export C_DOWNLOADS="$HOME/Downloads"
export C_MEDIA="$HOME/Videos"
export C_WEB_ROOT="/var/www"

primary_inet=$(route | grep '^default' | grep -m 1 -o '[^ ]*$')
all_ips=$(ip -o addr show scope global "$primary_inet" | awk '{gsub(/\/.*/,"",$4); print $4}')
export C_HOST_IPV4=$(awk 'NR==1' <<< "$all_ips")
export C_HOST_IPV6=$(awk 'NR==2' <<< "$all_ips")
export C_HOST_NET=$(ip route show scope link dev "$primary_inet" | cut -d' ' -f1)

unset primary_inet all_ips
# Unset IPV6 if it doesn't exist
[[ -z $C_HOST_IPV6 ]] && unset C_HOST_IPV6

# Print all
env | grep --color=never 'C\_'
```
