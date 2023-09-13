#!/bin/bash

MY_IP=$(hostname -I | awk '{print $1}')

SESSION="QuakeServers"

OSP_1V1_CMD="/usr/lib/ioquake3/ioq3ded +set fs_game osp +set vm_game 0 +set sv_pure 0 +set bot_enable 0 +set sv_punkbuster 0 +set dedicated 2 +set sv_master1 \"$MY_IP:27950\" +set sv_master2 '' +set sv_master3 '' +set sv_master4 '' +set sv_master5 '' +exec 1v1.cfg"
OSP_1V1_PORTS=(27970 27971 27972 27973)
RA3_CA_CMD="/usr/local/games/quake3/q3ded +set fs_game arena +set vm_game 0 +set sv_pure 0 +set bot_enable 0 +set sv_punkbuster 0 +set dedicated 2 +set sv_master1 \"$MY_IP:27950\" +set sv_master2 '' +set sv_master3 '' +set sv_master4 '' +set sv_master5 '' +set net_port 27980 +set sv_hostname 'Lanparty RA3' +exec server.cfg"
QL_CA_CMD="/home/lanparty/Steam/steamapps/common/Quake\ Live\ Dedicated\ Server/start_ql_ca.sh 27960"
QL_CTF_CMD="/home/lanparty/Steam/steamapps/common/Quake\ Live\ Dedicated\ Server/start_ql_ctf.sh 27961"
MY_PUBLIC_IP=$(curl -s https://ipecho.net/plain)

tmux -u new-session -d -s $SESSION /bin/bash

# Start master server
tmux send-keys "dpmaster -l 0.0.0.0:27950 -m $MY_IP=$MY_PUBLIC_IP" C-m 
tmux split-window -v -t $SESSION /bin/bash
tmux send-keys "htop -s PERCENT_CPU" C-m 
tmux select-pane -T "Master server" 

# Start 1v1 servers
for i in "${!OSP_1V1_PORTS[@]}"; do
	tmux split-window -v -t $SESSION /bin/bash
	tmux send-keys "$OSP_1V1_CMD +set net_port ${OSP_1V1_PORTS[$i]} +set sv_hostname \"Lanparty OSP 1v1 $(($i + 1)) ${OSP_1V1_PORTS[$i]}\"" C-m
	tmux select-pane -T "1v1 $(($i + 1)) ${OSP_1V1_PORTS[$i]}" 
	tmux select-layout tiled
done

tmux split-window -v -t $SESSION /bin/bash
tmux send-keys "$RA3_CA_CMD" C-m
tmux select-pane -T "RA3 27980"
tmux select-layout tiled

tmux split-window -v -t $SESSION /bin/bash
tmux send-keys "$QL_CA_CMD" C-m
tmux select-pane -T "QL CA 27960"
tmux select-layout tiled

tmux split-window -v -t $SESSION /bin/bash
tmux send-keys "$QL_CTF_CMD" C-m
tmux select-pane -T "QL CTF 27961"
tmux select-layout tiled

