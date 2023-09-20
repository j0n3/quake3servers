
get_port() {
    # Use given port or get a free one
    if [ -n "$1" ]; then
        PORT=$1
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
    echo $PORT
}