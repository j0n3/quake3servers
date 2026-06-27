#!/bin/bash
set -euo pipefail

DIR="$(dirname "$0")"
source /etc/quake_servers.conf
source "$DIR/common_functions.sh"

mkdir -p "${Q3SERVERS_LOG_DIR:-$Q3SERVERS_HOME/logs}"

MY_LAN_IP=$(get_my_lan_ip)
# A LAN party may have no internet access; fall back to the LAN IP so dpmaster
# still gets a valid public=lan mapping instead of "=<lan_ip>".
MY_INTERNET_IP=$(curl -s --max-time 5 https://ipecho.net/plain || true)
if [ -z "$MY_INTERNET_IP" ]; then
    MY_INTERNET_IP=$MY_LAN_IP
fi

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

if tmux has-session -t "$Q3SERVERS_TMUX_SESSION" 2>/dev/null; then
    echo "Session '$Q3SERVERS_TMUX_SESSION' is already running. Stop it first (q3servers stop)." >&2
    exit 1
fi

tmux -u new-session -d -s $Q3SERVERS_TMUX_SESSION /bin/bash

# Start master server (only if dpmaster is installed)
if command -v dpmaster >/dev/null 2>&1; then
    tmux send-keys "dpmaster -l 0.0.0.0:$Q3SERVERS_DPMASTER_PORT -m $MY_INTERNET_IP=$MY_LAN_IP" C-m
    tmux select-pane -T "Master server"
else
    echo "WARNING: dpmaster not found in PATH; starting without a LAN master server" >&2
    tmux select-pane -T "Master server (MISSING dpmaster)"
fi

# Start servers based on configurations
for SERVER_TYPE in "${!SERVER_CMDS[@]}"; do
    CMD="${SERVER_CMDS[$SERVER_TYPE]}"

    SERVER_ARRAY_VAR="Q3SERVERS_${SERVER_TYPE}[@]"
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
