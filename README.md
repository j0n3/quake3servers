# Quake3Servers for quake lan parties

Features:
- Starts multiple servers in a tmux session
- Supports Quake Live with minqlx, Quake 3 and ioQuake3
- Spawn new server scripts detect tmux session and attach to them or launch standalone
- Systemd service for automatic launch on startup and start/stop all of them
- Detects used port and spawn in a free one
- Spawn master server with dpmaster for q3 and ioq3

# Install

Target: a Debian/Ubuntu box. Everything runs as the `lanparty` user.

### 1. Clone the repo somewhere permanent

The installer **symlinks** the repo into the system (it does not copy it), so
don't clone it into a temp dir or a private home — `lanparty` must be able to
read it.

```bash
sudo git clone <this-repo> /opt/quake3servers
cd /opt/quake3servers
```

### 2. Edit the settings

Edit `quake_servers.env` (it ends up symlinked as `/etc/quake_servers.env`):

- `Q3SERVERS_RCON_PASSWORD` — **change it**.
- `Q3SERVERS_PASSWORD` — join password (empty = open server).
- `Q3SERVERS_QLX_OWNER` — your SteamID64 (minqlx admin).
- `Q3SERVERS_HOSTNAME` — the installer sets the box's hostname from this.

Which servers start, and on which ports, is set in `quake_servers.conf`
(`mode:port1:port2:...`, one server per port).

### 3. Run the installer

```bash
sudo ./install.sh
```

It is idempotent: you can re-run it, or run just some steps
(`sudo ./install.sh quakelive avahi`). At the end it asks whether to start the
servers — say **no** the first time; game data comes in the next step.

| Step        | What it does |
|-------------|--------------|
| `deps`      | System packages (tmux, git, python, redis, avahi, ioquake3, 32-bit libs…) |
| `user`      | Creates the `lanparty` service user |
| `symlinks`  | Links the repo, config, service and CLI into the system (see [Paths](#paths)), creates the log dir |
| `dpmaster`  | Clones + builds dpmaster → `/usr/local/bin/dpmaster` |
| `redis`     | Enables Redis (minqlx backend) |
| `ioquake3`  | Checks for `ioq3ded` |
| `quake3`    | Creates `/usr/local/games/quake3/{baseq3,arena}` |
| `quakelive` | steamcmd → QLDS + minqlx + plugins + python venv |
| `avahi`     | Sets hostname + mDNS so clients reach `lanparty.local` |
| `service`   | Enables (and optionally starts) the systemd service |

### 4. Add the game files by hand

The game data is copyrighted, so the installer can't download it. Copy each file
into its folder and make `lanparty` the owner
(`sudo chown -R lanparty: <dir>`).

**ioquake3** (modes `1v1`, `ffa`, `instagib`, `freezetag`, `team`; mod `osp`)

| File | Goes to |
|------|---------|
| Retail `pak0.pk3` + point-release `pak1..8.pk3` | `/usr/share/games/quake3/baseq3/` |
| OSP mod (its `.pk3` files) | `/home/lanparty/.q3a/osp/` |
| `configs/ioq3/*.cfg` (this repo) | `/home/lanparty/.q3a/osp/` |

**Quake 3 Arena 1.32** (mode `arena`, Rocket Arena 3)

| File | Goes to |
|------|---------|
| `q3ded` binary (1.32 point release), executable | `/usr/local/games/quake3/q3ded` |
| Retail `pak0.pk3` .. `pak8.pk3` | `/usr/local/games/quake3/baseq3/` |
| Rocket Arena 3 mod | `/usr/local/games/quake3/arena/` |
| `configs/q3/server.cfg` (this repo) | `/usr/local/games/quake3/arena/` |

**Quake Live** (installed automatically by the installer; you only add configs)

| File | Goes to |
|------|---------|
| `configs/ql/mappool*.txt` (this repo) | `/home/lanparty/Steam/steamapps/common/Quake Live Dedicated Server/baseq3/` |

Check that every map in the mappools is installed: some need Steam Workshop items.

For example, the repo configs:

```bash
QL="/home/lanparty/Steam/steamapps/common/Quake Live Dedicated Server"
sudo -u lanparty mkdir -p /home/lanparty/.q3a/osp
sudo -u lanparty cp configs/ioq3/*.cfg /home/lanparty/.q3a/osp/
sudo cp configs/q3/server.cfg /usr/local/games/quake3/arena/
sudo -u lanparty cp configs/ql/mappool*.txt "$QL/baseq3/"
sudo chown -R lanparty: /usr/local/games/quake3
```

You only need the games you plan to run: remove the rest from
`quake_servers.conf` (e.g. `Q3SERVERS_Q3=()`).

### 5. Start and check

```bash
sudo q3servers start
q3servers status
sudo -u lanparty q3servers attach      # Ctrl-b d to detach
q3servers logs                         # list logs, then: q3servers logs <name>
```

If a server dies on startup, its pane and its log in `/var/log/quake3servers/`
say why (usually a missing `.pk3` or `.cfg`).

## Paths

What the installer leaves where (defaults from `quake_servers.env`):

| Path | What |
|------|------|
| `/usr/local/games/quake3servers` | → symlink to the repo |
| `/etc/quake_servers.conf`, `/etc/quake_servers.env` | → symlinks to the repo's config |
| `/etc/systemd/system/quake_servers.service` | → symlink to the repo's service |
| `/usr/local/bin/q3servers` | → symlink to the control CLI |
| `/usr/local/bin/dpmaster` | master server (built from source) |
| `/usr/lib/ioquake3/ioq3ded` | ioquake3 server (Debian `ioquake3` package) |
| `/usr/local/games/quake3/` | Quake 3 1.32 (`q3ded`, `baseq3/`, `arena/`) |
| `/home/lanparty/Steam/steamapps/common/Quake Live Dedicated Server/` | QLDS + minqlx + `minqlx-plugins/` + venv `minqlx/` |
| `/var/log/quake3servers/` | one log per server |

Since the config files are symlinks, editing `quake_servers.env` in the repo
changes the live config. Restart afterwards: `sudo q3servers restart`.

# Configuration

Settings are split in two files:

- **`quake_servers.env`**: scalar `KEY=value` settings (hostname, paths,
  passwords, FPS, Redis, minqlx owner/plugins). systemd also reads it directly.
- **`quake_servers.conf`**: sources the `.env` and adds the server definitions.
  These are bash arrays (`mode:port1:port2:...`) that systemd can't parse.

# Control (q3servers CLI)

```bash
q3servers status              # systemd + tmux state
q3servers list                # running servers (tmux panes)
q3servers attach              # attach to the tmux session
q3servers start|stop|restart  # control the systemd service
q3servers add ioq3 1v1 [port] # spawn one extra server (game: ioq3|q3|ql)
q3servers logs [name]         # tail a server log
```

tmux-based commands (`list`, `attach`, `add`) run as the service user, e.g.
`sudo -u lanparty q3servers attach`.

# TODO:

- Quake 3 retail data + 1.32 point release (manual: copyrighted)
    - ra3 (Rocket Arena 3)
    - RA3 autoexec is not loaded so can't place 200-100, falling damage... :(
- ioquake3 osp mod + extra maps
- Verify minqlx build artifacts layout on target box
- config files (per-gametype .cfg), extra maps, extra mods

- Other server mods
    - instagib
    - freeze tag
    - defrag/race
    - red rover
    - More mods for QL (requires workshop items) https://steamcommunity.com/app/282440/discussions/0/490125103624446696/

- NTH:
    Web:
        Web server to spawn or kill servers. Also rcon commands?
        Web to browse servers
        Download links (official or hosted)
    QL Factories
    Publish match results on discord (screenshot?)
    Record matches
    Add workshop items for minqlx sounds
    Add match stats and other minqlx plugins
