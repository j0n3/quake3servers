#!/bin/bash

DIR="$(dirname "$0")"
source /etc/quake_servers.conf
source "$DIR/common_functions.sh"

GAMETYPE="${1,,}"
case $GAMETYPE in
"arena" | "ra3")
    FS_GAME=arena
    ;;
*)
    echo "Usage: $0 <arena> [port]"
    exit 1
    ;;
esac

PORT=$(get_port "$2")

SV_HOSTNAME="$GAMETYPE $PORT"
MY_LAN_IP=$(get_my_lan_ip)

START_SERVER="\"$Q3SERVERS_Q3_EXEC\" \
    +set fs_game \"$FS_GAME\" \
    +set sv_password \"$Q3SERVERS_PASSWORD\" \
    +set vm_game 0 \
    +set sv_pure 0 \
    +set bot_enable 0 \
    +set sv_punkbuster 0 \
    +set dedicated 2 \
    +set sv_master1 \"$MY_LAN_IP:$Q3SERVERS_DPMASTER_PORT\" \
    +set sv_master2 '' \
    +set sv_master3 '' \
    +set sv_master4 '' \
    +set sv_master5 '' \
    +set net_port \"$PORT\" \
    +set sv_hostname \"$SV_HOSTNAME\" \
    +set sv_dlRate 1000000 \
    +set sv_allowDownload 1 \
    +set sv_fps \"$Q3SERVERS_Q3_SV_FPS\" \
    +exec server.cfg"

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