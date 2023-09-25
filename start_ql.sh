#!/bin/bash

DIR="$(dirname "$0")"
source /etc/quake_servers.conf
source "$DIR/common_functions.sh"

MY_IP=$(hostname -I | awk '{print $1}')

VENV_DIR="$Q3SERVERS_STEAM_QL_HOME/minqlx"

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

if [ "$VIRTUAL_ENV" != "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

GAMETYPE="${1,,}"
case $GAMETYPE in
"ctf")
    SV_GAMETYPE=5
    SV_MAPPOOL_FILE=mappool_ctf.txt
    ;;
"ca")
    SV_GAMETYPE=4
    SV_MAPPOOL_FILE=mappool_ca.txt
    ;;
*)
    echo "Usage: $0 <ctf|ca> [port]"
    exit 1
    ;;
esac

PORT=$(get_port "$2")

SV_HOSTNAME="^2Lan^6party $GAMETYPE $PORT"

START_SERVER="\"$Q3SERVERS_STEAM_QL_HOME/run_server_x64_minqlx.sh\" +set net_port \"$PORT\" \
    +set sv_hostname \"$SV_HOSTNAME\" \
    +set sv_serverType 2 \
    +set g_password \"$Q3SERVERS_PASSWORD\" +sv_fps \"$Q3SERVERS_QL_SV_FPS\" \
    +set g_gametype \"$SV_GAMETYPE\" \
    +set qlx_redisAddress \"$Q3SERVERS_REDIS_HOST\" \
    +set qlx_redisPort \"$Q3SERVERS_REDIS_PORT\" \
    +set qlx_redisPassword \"$Q3SERVERS_REDIS_PASSWORD\" \
    +set qlx_redisDatabase \"$Q3SERVERS_REDIS_DB\" \
    +set qlx_owner \"$Q3SERVERS_QLX_OWNER\" \
    +set qlx_plugins \"$Q3SERVERS_QLX_PLUGINS\" \
    +set sv_mapPoolFile \"$SV_MAPPOOL_FILE\" \
    +set sv_master2 '' \
    +set sv_master3 '' \
    +set sv_master4 '' \
    +set sv_master5 ''"

tmux has-session -t "$Q3SERVERS_TMUX_SESSION" 2>/dev/null
if [ $? -eq 0 ] && [ -z "$TMUX" ]; then
    tmux split-window -v -t "$Q3SERVERS_TMUX_SESSION" /bin/bash
    tmux send-keys "$START_SERVER" C-m
    tmux select-pane -T "QL ${GAMETYPE} ${PORT}"
    tmux select-layout tiled
    echo "Server added to tmux session $Q3SERVERS_TMUX_SESSION"
else
    eval "$START_SERVER"
fi