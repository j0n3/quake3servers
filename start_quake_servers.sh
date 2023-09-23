#!/bin/bash

source /etc/quake_servers.conf

MY_LAN_IP=$(hostname -I | awk '{print $1}')
MY_INTERNET_IP=$(curl -s https://ipecho.net/plain)

IOQ3_CMD="$Q3SERVERS_HOME/start_ioq3.sh"
Q3_CMD="$Q3SERVERS_HOME/start_q3.sh"
QL_CMD="$Q3SERVERS_HOME/start_ql.sh"

start_servers() {
	local cmd="$1"
	local game_type="$2"
	shift 2
	local ports=("$@")

	for i in "${!ports[@]}"; do
		tmux split-window -v -t $Q3SERVERS_TMUX_SESSION /bin/bash
		tmux send-keys "$cmd $game_type ${ports[$i]}" C-m
		tmux select-pane -T "$game_type $(($i + 1)) ${ports[$i]}"
		tmux select-layout tiled
	done
}

tmux -u new-session -d -s $Q3SERVERS_TMUX_SESSION /bin/bash

# Start master server
tmux send-keys "dpmaster -l 0.0.0.0:27950 -m $MY_LAN_IP=$MY_INTERNET_IP" C-m
tmux select-pane -T "Master server"

IFS=' ' read -ra Q3SERVERS_IOQ3_1V1_PORTS <<<"$Q3SERVERS_IOQ3_1V1_PORTS"
IFS=' ' read -ra Q3SERVERS_Q3_RA3_PORTS <<<"$Q3SERVERS_Q3_RA3_PORTS"
IFS=' ' read -ra Q3SERVERS_QL_CA_PORTS <<<"$Q3SERVERS_QL_CA_PORTS"
IFS=' ' read -ra Q3SERVERS_QL_CTF_PORTS <<<"$Q3SERVERS_QL_CTF_PORTS"

# Start servers
start_servers "$IOQ3_CMD" "1v1" "${Q3SERVERS_IOQ3_1V1_PORTS[@]}"
start_servers "$Q3_CMD" "RA3" "${Q3SERVERS_Q3_RA3_PORTS[@]}"
start_servers "$QL_CMD" "CA" "${Q3SERVERS_QL_CA_PORTS[@]}"
start_servers "$QL_CMD" "CTF" "${Q3SERVERS_QL_CTF_PORTS[@]}"

echo "Tmux session $Q3SERVERS_TMUX_SESSION started"
echo "Use 'tmux attach -t $Q3SERVERS_TMUX_SESSION' to attach to the session"
echo "or just 'tmux a' if you don't have other sessions running"
