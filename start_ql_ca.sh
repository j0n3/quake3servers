#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Activate python virtualenv?
if [ "$VIRTUAL_ENV" != "$SCRIPT_DIR/minqlx" ]; then
    source "$SCRIPT_DIR/minqlx/bin/activate"
fi

# Detect port
if [ -n "$1" ]; then
    PORT=$1
else
    PORT=27960
    while :
    do
        (echo > /dev/tcp/127.0.0.1/$PORT) >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo $PORT
            break
        fi
        PORT=$((PORT + 1))
    done
fi

SV_HOSTNAME="Lanparty CA Server $1"

"$SCRIPT_DIR/run_server_x64_minqlx.sh" +set net_port $PORT +set sv_hostname $SV_HOSTNAME +set sv_serverType 2 +set g_password lanparty +sv_fps 120 +set g_gametype 4 +set qlx_redisAddress 127.0.0.1 +set qlx_redisPort 6379 +set qlx_redisPassword "" +set qlx_owner 76561198004911379 +set qlx_plugins  "plugin_manager, essentials, motd, permission, ban, silence, clan, names, log, workshop, balance, fun" +set qlx_redisDatabase 0 +set sv_mapPoolFile mappool_ca.txt +set sv_master1 "lanparty.local:27950" +set sv_master2 '' +set sv_master3 '' +set sv_master4 '' +set sv_master5 ''
