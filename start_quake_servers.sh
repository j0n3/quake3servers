#!/bin/bash

source /etc/quake_servers.conf

MY_LAN_IP=$(hostname -I | awk '{print $1}')
MY_INTERNET_IP=$(curl -s https://ipecho.net/plain)

declare -A SERVER_CMDS=(
    [IOQ3]="$Q3SERVERS_HOME/start_ioq3.sh"
    [Q3]="$Q3SERVERS_HOME/start_q3.sh"
    [QL]="$Q3SERVERS_HOME/start_ql.sh"
)

start_servers() {
	local cmd="$1"
	local game_type="$2"
	shift 2
	local ports=("$@")

	for port in "${ports[@]}"; do
		tmux split-window -v -t $Q3SERVERS_TMUX_SESSION /bin/bash
		tmux send-keys "$cmd $game_type $port" C-m
		tmux select-pane -T "$game_type $port"
		tmux select-layout tiled
	done
}

tmux -u new-session -d -s $Q3SERVERS_TMUX_SESSION /bin/bash

# Start master server
tmux send-keys "dpmaster -l 0.0.0.0:27950 -m $MY_INTERNET_IP=$MY_LAN_IP" C-m
tmux select-pane -T "Master server"

# Start servers based on configurations
for SERVER_TYPE in IOQ3 Q3 QL; do
	eval "SERVERS_ARRAY=(\"\${Q3SERVERS_$SERVER_TYPE[@]}\")"
    for entry in "${SERVERS_ARRAY[@]}"; do
        IFS=":" read -ra parts <<< "$entry"
        GAMETYPE="${parts[0]}"
        PORTS=("${parts[@]:1}")
        CMD="${SERVER_CMDS[$SERVER_TYPE]}"
        start_servers "$CMD" "$GAMETYPE" "${PORTS[@]}"
    done
done

echo "Tmux session $Q3SERVERS_TMUX_SESSION started"
echo "Use 'tmux attach -t $Q3SERVERS_TMUX_SESSION' to attach to the session"
