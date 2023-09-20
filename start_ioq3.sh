#!/bin/bash

source /etc/quake_servers.conf

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

# Use given port or get a free one
if [ -n "$2" ]; then
    PORT=$2
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

SV_HOSTNAME="^2Lan^6party $GAMETYPE $PORT"

"$Q3SERVERS_IOQ3_EXEC" \
 +set fs_game $FS_GAME\
 +set vm_game 0\
 +set sv_pure 0\
 +set bot_enable 0\
 +set sv_punkbuster 0\
 +set dedicated 2\
 +set sv_master1 "$MY_IP:$Q3SERVERS_DPMASTER_PORT"\
 +set sv_master2 ''\
 +set sv_master3 ''\
 +set sv_master4 ''\
 +set sv_master5 ''\
 +set net_port "$PORT" \
 +set sv_hostname "$SV_HOSTNAME" \
 +exec $SERVER_CONFIG