
port_in_use() {
    # Quake servers listen on UDP, so probe UDP. Falls back to a TCP probe
    # (which can't see UDP-only listeners) when ss is unavailable.
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -lunH "sport = :$port" 2>/dev/null | grep -q .
    else
        (echo > "/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1
    fi
}

get_port() {
    # Use the given port, or find the first free UDP port starting at 27960.
    if [ -n "${1:-}" ]; then
        echo "$1"
        return
    fi

    local port=27960
    while port_in_use "$port"; do
        port=$((port + 1))
    done
    echo "$port"
}

get_my_lan_ip() {
    # Prefer the source IP the kernel would use to reach the LAN (derived from
    # the default route) so we don't accidentally pick a docker/libvirt/VPN
    # bridge address. Fall back to the first hostname -I entry.
    local ip
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
    if [ -z "$ip" ]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "$ip"
}