#!/bin/bash

DIR="$(dirname "$0")"
source /etc/quake_servers.conf
source "$DIR/common_functions.sh"

MY_IP=$(hostname -I | awk '{print $1}')

GAMETYPE="${1,,}"
case $GAMETYPE in
"1v1")
    FS_GAME=osp
    SERVER_CONFIG=1v1.cfg
    ;;
*)
    echo "Usage: $0 <osp> [port]"
    exit 1
    ;;
esac

PORT=$(get_port "$2")

SV_HOSTNAME="^2Lan^6party $GAMETYPE $PORT"

"$Q3SERVERS_IOQ3_EXEC" \
    +set fs_game $FS_GAME \
    +set vm_game 0 \
    +set sv_pure 0 \
    +set bot_enable 0 \
    +set sv_punkbuster 0 \
    +set dedicated 2 \
    +set sv_master1 "$MY_IP:$Q3SERVERS_DPMASTER_PORT" \
    +set sv_master2 '' \
    +set sv_master3 '' \
    +set sv_master4 '' \
    +set sv_master5 '' \
    +set net_port "$PORT" \
    +set sv_hostname "$SV_HOSTNAME" \
    +exec $SERVER_CONFIG
