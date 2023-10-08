#!/bin/bash

DIR="$(dirname "$0")"
source /etc/quake_servers.conf
source "$DIR/common_functions.sh"

MY_LAN_IP=$(get_my_lan_ip)
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
for SERVER_TYPE in "${!SERVER_CMDS[@]}"; do
    CMD="${SERVER_CMDS[$SERVER_TYPE]}"
    
    SERVER_ARRAY_VAR="Q3SERVERS_$SERVER_TYPE[@]"
    SERVER_ARRAY=("${!SERVER_ARRAY_VAR}")
    
    for ENTRY in "${SERVER_ARRAY[@]}"; do
        IFS=":" read -ra SPLIT_ENTRY <<< "$ENTRY"
        GAMETYPE="${SPLIT_ENTRY[0]}"
        PORTS=("${SPLIT_ENTRY[@]:1}")
        start_servers "$CMD" "$GAMETYPE" "${PORTS[@]}"
    done
done

echo "Tmux session $Q3SERVERS_TMUX_SESSION started"
echo "Use 'tmux attach -t $Q3SERVERS_TMUX_SESSION' to attach to the session"
