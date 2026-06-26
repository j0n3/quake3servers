#!/bin/bash
#
# Quake3Servers installer.
#
# Clone this repo onto a (Debian/Ubuntu) machine and run:
#
#     sudo ./install.sh
#
# It performs the full setup: system packages, the "lanparty" service user,
# symlinks into /etc + /usr/local, dpmaster, Redis, ioquake3, Quake 3 Arena and
# the Quake Live dedicated server (steamcmd) with minqlx + plugins, avahi/mDNS,
# and finally the systemd service.
#
# Every step is idempotent: re-running is safe. You can also run a single step:
#
#     sudo ./install.sh dpmaster
#     sudo ./install.sh quakelive avahi
#
# Steps that need copyrighted game data (Quake 3 retail .pk3 files) cannot be
# automated; the installer sets up the engine and tells you exactly what to drop
# in and where.

set -uo pipefail

# --------------------------------------------------------------------------- #
# Paths / config                                                              #
# --------------------------------------------------------------------------- #

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$REPO_DIR/quake_servers.conf"
ENV_SRC="$REPO_DIR/quake_servers.env"
SERVICE_SRC="$REPO_DIR/quake_servers.service"
CLI_SRC="$REPO_DIR/q3servers"

# Pull the canonical paths/user from the repo's config so this stays in sync.
# shellcheck source=quake_servers.conf
source "$CONF_SRC"

SERVICE_DST="/etc/systemd/system/quake_servers.service"
CONF_DST="/etc/quake_servers.conf"
ENV_DST="/etc/quake_servers.env"
CLI_DST="/usr/local/bin/q3servers"
DPMASTER_SRC_DIR="/usr/local/src/dpmaster"
MINQLX_SRC_DIR="/usr/local/src/minqlx"
QL_APPID=349090   # Quake Live Dedicated Server on Steam (anonymous-installable)

# Short hostname derived from e.g. "lanparty.local" -> "lanparty"
HOST_SHORT="${Q3SERVERS_HOSTNAME%%.*}"
USER_HOME="$(getent passwd "$Q3SERVERS_USER" | cut -d: -f6)"
USER_HOME="${USER_HOME:-/home/$Q3SERVERS_USER}"

# --------------------------------------------------------------------------- #
# Logging helpers                                                             #
# --------------------------------------------------------------------------- #

log()  { echo -e "\033[1;32m[*]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; }
step() { echo -e "\n\033[1;36m=== $* ===\033[0m"; }

# Run a command as the lanparty service user, with its own HOME.
as_user() { sudo -u "$Q3SERVERS_USER" -H "$@"; }

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        err "This installer must run as root. Use: sudo ./install.sh"
        exit 1
    fi
}

# --------------------------------------------------------------------------- #
# Steps                                                                        #
# --------------------------------------------------------------------------- #

install_system_deps() {
    step "Installing system dependencies"
    if ! command -v apt-get >/dev/null 2>&1; then
        err "apt-get not found. This installer targets Debian/Ubuntu."
        exit 1
    fi
    export DEBIAN_FRONTEND=noninteractive
    dpkg --add-architecture i386   # 32-bit libs needed by Steam / QLDS
    apt-get update
    apt-get install -y \
        tmux git curl ca-certificates make gcc build-essential \
        python3 python3-pip python3-venv python3-dev python3-redis \
        redis-server avahi-daemon libnss-mdns \
        lib32gcc-s1 lib32stdc++6 \
        zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev \
        libsqlite3-dev libreadline-dev libffi-dev libbz2-dev \
        ioquake3 || { err "Package installation failed"; exit 1; }
    log "System dependencies installed"
}

create_user() {
    step "Creating service user '$Q3SERVERS_USER'"
    if id "$Q3SERVERS_USER" >/dev/null 2>&1; then
        log "User '$Q3SERVERS_USER' already exists"
    else
        useradd --create-home --shell /bin/bash "$Q3SERVERS_USER"
        log "Created user '$Q3SERVERS_USER' (home: $USER_HOME)"
    fi
}

install_symlinks() {
    step "Linking repo, config and service into the system"

    # Repo -> /usr/local/games/quake3servers
    mkdir -p "$(dirname "$Q3SERVERS_HOME")"
    if [ "$(readlink -f "$Q3SERVERS_HOME" 2>/dev/null)" != "$REPO_DIR" ]; then
        ln -sfn "$REPO_DIR" "$Q3SERVERS_HOME"
    fi
    log "$Q3SERVERS_HOME -> $REPO_DIR"

    # Config -> /etc/quake_servers.conf  (+ the scalar .env it sources)
    ln -sfn "$CONF_SRC" "$CONF_DST"
    ln -sfn "$ENV_SRC" "$ENV_DST"
    log "$CONF_DST -> $CONF_SRC"
    log "$ENV_DST -> $ENV_SRC"

    # Service -> /etc/systemd/system/
    ln -sfn "$SERVICE_SRC" "$SERVICE_DST"
    log "$SERVICE_DST -> $SERVICE_SRC"

    # Control CLI -> /usr/local/bin/q3servers
    ln -sfn "$CLI_SRC" "$CLI_DST"
    log "$CLI_DST -> $CLI_SRC"

    # Log directory (servers tee their output here)
    mkdir -p "$Q3SERVERS_LOG_DIR"
    chown "$Q3SERVERS_USER":"$Q3SERVERS_USER" "$Q3SERVERS_LOG_DIR" 2>/dev/null || true
    log "Log dir: $Q3SERVERS_LOG_DIR"

    systemctl daemon-reload
}

install_dpmaster() {
    step "Building dpmaster (LAN master server)"
    if [ ! -d "$DPMASTER_SRC_DIR/.git" ]; then
        git clone https://github.com/kphillisjr/dpmaster/ "$DPMASTER_SRC_DIR"
    else
        git -C "$DPMASTER_SRC_DIR" pull --ff-only || warn "Could not update dpmaster, using existing checkout"
    fi
    make -C "$DPMASTER_SRC_DIR" || { err "dpmaster build failed"; return 1; }

    local bin
    bin="$(find "$DPMASTER_SRC_DIR" -maxdepth 3 -type f -name dpmaster -executable | head -n1)"
    if [ -z "$bin" ]; then
        err "Could not locate the built dpmaster binary"
        return 1
    fi
    install -m 0755 "$bin" /usr/local/bin/dpmaster
    log "Installed dpmaster -> /usr/local/bin/dpmaster"
}

setup_redis() {
    step "Enabling Redis (used by minqlx)"
    systemctl enable --now redis-server 2>/dev/null \
        || systemctl enable --now redis 2>/dev/null \
        || warn "Could not enable redis service automatically"
    log "Redis enabled"
}

install_ioquake3() {
    step "Setting up ioquake3"
    if [ -x "$Q3SERVERS_IOQ3_EXEC" ]; then
        log "ioquake3 dedicated server present: $Q3SERVERS_IOQ3_EXEC"
    else
        warn "Expected ioq3ded at $Q3SERVERS_IOQ3_EXEC but it is missing."
        warn "The 'ioquake3' package should provide it; verify the package installed."
    fi
    warn "Remember to place baseq3/pak0.pk3 (retail data) and the 'osp' mod under the ioquake3 data dir."
}

install_quake3() {
    step "Setting up Quake 3 Arena (id Tech 3 / q3ded)"
    local q3_dir
    q3_dir="$(dirname "$Q3SERVERS_Q3_EXEC")"
    mkdir -p "$q3_dir/baseq3" "$q3_dir/arena"
    chown -R "$Q3SERVERS_USER":"$Q3SERVERS_USER" "$q3_dir"
    if [ -x "$Q3SERVERS_Q3_EXEC" ]; then
        log "q3ded present: $Q3SERVERS_Q3_EXEC"
    else
        warn "q3ded not found at $Q3SERVERS_Q3_EXEC."
        warn "Quake 3 retail (id software) is copyrighted and cannot be auto-downloaded."
        warn "Provide the 1.32 point-release q3ded binary and place it there, plus:"
        warn "  - baseq3/pak0.pk3 .. pak8.pk3   (retail data)"
        warn "  - arena/                        (Rocket Arena 3 mod)"
        warn "RA3 autoexec is currently not loaded (known issue in README TODO)."
    fi
}

install_quakelive() {
    step "Installing Quake Live Dedicated Server (steamcmd + minqlx)"

    # --- steamcmd ---------------------------------------------------------- #
    if ! command -v steamcmd >/dev/null 2>&1; then
        # steamcmd lives in non-free; enable it and accept the Steam license.
        add-apt-repository -y multiverse 2>/dev/null || true
        echo steam steam/question select "I AGREE" | debconf-set-selections
        echo steam steam/license note '' | debconf-set-selections
        DEBIAN_FRONTEND=noninteractive apt-get install -y steamcmd \
            || { warn "Could not install steamcmd via apt; install it manually and re-run: sudo ./install.sh quakelive"; return 1; }
    fi

    # --- QLDS via anonymous steamcmd --------------------------------------- #
    log "Downloading/updating Quake Live Dedicated Server (app $QL_APPID)..."
    as_user steamcmd \
        +force_install_dir "$Q3SERVERS_STEAM_QL_HOME" \
        +login anonymous \
        +app_update "$QL_APPID" validate \
        +quit || { err "steamcmd failed to install QLDS"; return 1; }

    # --- minqlx ------------------------------------------------------------ #
    log "Building minqlx..."
    if [ ! -d "$MINQLX_SRC_DIR/.git" ]; then
        git clone --recursive https://github.com/MinoMino/minqlx "$MINQLX_SRC_DIR"
    else
        git -C "$MINQLX_SRC_DIR" pull --ff-only || warn "Could not update minqlx"
    fi
    if make -C "$MINQLX_SRC_DIR"; then
        # Copy the build artifacts (loader script + libs) into the QLDS root.
        cp -av "$MINQLX_SRC_DIR"/bin/* "$Q3SERVERS_STEAM_QL_HOME"/ 2>/dev/null || \
            warn "minqlx build produced no bin/; check $MINQLX_SRC_DIR for the loader (run_server_x64_minqlx.sh) and copy it into the QLDS dir."
    else
        warn "minqlx build failed; QL servers will not load minqlx until it is built."
    fi

    # --- minqlx plugins ---------------------------------------------------- #
    local plugins_dir="$Q3SERVERS_STEAM_QL_HOME/minqlx-plugins"
    if [ ! -d "$plugins_dir/.git" ]; then
        as_user git clone https://github.com/MinoMino/minqlx-plugins "$plugins_dir"
    else
        as_user git -C "$plugins_dir" pull --ff-only || warn "Could not update minqlx-plugins"
    fi

    # --- python venv + plugin requirements --------------------------------- #
    # start_ql.sh activates a venv at "$Q3SERVERS_STEAM_QL_HOME/minqlx".
    local venv_dir="$Q3SERVERS_STEAM_QL_HOME/minqlx"
    if [ ! -d "$venv_dir/bin" ]; then
        as_user python3 -m venv "$venv_dir"
    fi
    as_user "$venv_dir/bin/pip" install --upgrade pip redis
    if [ -f "$plugins_dir/requirements.txt" ]; then
        as_user "$venv_dir/bin/pip" install -r "$plugins_dir/requirements.txt" \
            || warn "Some plugin requirements failed to install"
    fi

    chown -R "$Q3SERVERS_USER":"$Q3SERVERS_USER" "$Q3SERVERS_STEAM_QL_HOME" 2>/dev/null || true
    log "Quake Live dedicated server set up at: $Q3SERVERS_STEAM_QL_HOME"
}

setup_avahi() {
    step "Configuring hostname + avahi/mDNS ($Q3SERVERS_HOSTNAME)"

    # Set the system hostname so mDNS advertises <hostname>.local
    if [ "$(hostname)" != "$HOST_SHORT" ]; then
        hostnamectl set-hostname "$HOST_SHORT" 2>/dev/null || hostname "$HOST_SHORT"
        log "Hostname set to $HOST_SHORT"
    fi

    # Ensure /etc/hosts resolves it locally
    if ! grep -qE "[[:space:]]$HOST_SHORT([[:space:]]|\$)" /etc/hosts; then
        echo "127.0.1.1 $HOST_SHORT $Q3SERVERS_HOSTNAME" >> /etc/hosts
        log "Added '$HOST_SHORT' to /etc/hosts"
    fi

    systemctl enable --now avahi-daemon 2>/dev/null || warn "Could not enable avahi-daemon"
    log "avahi/mDNS enabled — clients can reach the box at $Q3SERVERS_HOSTNAME"
}

enable_service() {
    step "Enabling the quake_servers systemd service"
    systemctl daemon-reload
    systemctl enable quake_servers.service
    log "Service enabled (will start on boot)"

    read -rp "Start the servers now? [Y/n] " response
    response="${response,,}"
    if [[ -z "$response" || "$response" == "y" ]]; then
        systemctl start quake_servers.service
        log "Service started. Attach with: sudo -u $Q3SERVERS_USER tmux attach -t $Q3SERVERS_TMUX_SESSION"
    else
        log "Start it later with: sudo systemctl start quake_servers.service"
    fi
}

# --------------------------------------------------------------------------- #
# Dispatcher                                                                   #
# --------------------------------------------------------------------------- #

declare -A STEPS=(
    [deps]=install_system_deps
    [user]=create_user
    [symlinks]=install_symlinks
    [dpmaster]=install_dpmaster
    [redis]=setup_redis
    [ioquake3]=install_ioquake3
    [quake3]=install_quake3
    [quakelive]=install_quakelive
    [avahi]=setup_avahi
    [service]=enable_service
)

# Order matters (deps first, service last).
STEP_ORDER=(deps user symlinks dpmaster redis ioquake3 quake3 quakelive avahi service)

usage() {
    echo "Usage: sudo ./install.sh [step ...]"
    echo "Steps (default: all, in order):"
    printf '  %s\n' "${STEP_ORDER[@]}"
}

main() {
    require_root

    local to_run=("${STEP_ORDER[@]}")
    if [ "$#" -gt 0 ]; then
        case "$1" in
            -h|--help) usage; exit 0 ;;
        esac
        to_run=("$@")
        for s in "${to_run[@]}"; do
            if [ -z "${STEPS[$s]:-}" ]; then
                err "Unknown step: $s"; usage; exit 1
            fi
        done
    fi

    for s in "${to_run[@]}"; do
        "${STEPS[$s]}"
    done

    echo
    log "Done. Config: $CONF_DST  |  Repo: $Q3SERVERS_HOME"
}

main "$@"
