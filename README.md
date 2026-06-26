# Quake3Servers for quake lan parties

Features:
- Starts multiple servers in a tmux session
- Supports Quake Live with minqlx, Quake 3 and ioQuake3
- Spawn new server scripts detect tmux session and attach to them or launch standalone
- Systemd service for automatic launch on startup and start/stop all of them
- Detects used port and spawn in a free one
- Spawn master server with dpmaster for q3 and ioq3

# Install

Clone the repo onto a Debian/Ubuntu box and run the installer:

```bash
git clone <this-repo> quake3servers
cd quake3servers
sudo ./install.sh
```

It is idempotent and runs these steps in order (run a subset with
`sudo ./install.sh <step ...>`):

| Step        | What it does |
|-------------|--------------|
| `deps`      | System packages (tmux, git, python, redis, avahi, 32-bit libs…) |
| `user`      | Creates the `lanparty` service user |
| `symlinks`  | Links repo→`/usr/local/games/quake3servers`, `.conf`+`.env`→`/etc`, `.service`→systemd, `q3servers` CLI→`/usr/local/bin`, creates the log dir |
| `dpmaster`  | Clones + builds dpmaster, installs to `/usr/local/bin` |
| `redis`     | Enables Redis (minqlx backend) |
| `ioquake3`  | Verifies the ioq3 dedicated server |
| `quake3`    | Prepares the q3ded data dirs |
| `quakelive` | steamcmd → QLDS + minqlx + plugins + python venv |
| `avahi`     | Sets hostname + mDNS so clients reach `lanparty.local` |
| `service`   | Enables (and optionally starts) the systemd service |

Copyrighted game data cannot be downloaded automatically — the installer tells
you where to drop the Quake 3 retail `.pk3` files and the q3ded / mods.

# Configuration

Settings are split in two files:

- **`quake_servers.env`** — scalar `KEY=value` settings (hostname, paths,
  passwords, FPS, Redis, minqlx owner/plugins). Also read directly by systemd.
- **`quake_servers.conf`** — sources the `.env` and adds the server definitions,
  which are bash arrays (`mode:port1:port2:...`) systemd can't parse.

Set `Q3SERVERS_RCON_PASSWORD` in the `.env` before a real party. Sample
per-gametype files live in `configs/` — copy them into place:
- `configs/ioq3/*.cfg`, `configs/q3/server.cfg` → the matching `fs_game` mod dir
  (e.g. `osp/`, `arena/`).
- `configs/ql/mappool_*.txt` → the QLDS dir (referenced by `sv_mapPoolFile`).
  Verify each map is installed — some require Steam Workshop items.

# Control (q3servers CLI)

```bash
q3servers status              # systemd + tmux state
q3servers list                # running servers (tmux panes)
q3servers attach              # attach to the tmux session
q3servers start|stop|restart  # control the systemd service
q3servers add ioq3 1v1 [port] # spawn one extra server (game: ioq3|q3|ql)
q3servers logs [name]         # tail a server log
```

tmux-based commands run as the service user, e.g. `sudo -u lanparty q3servers attach`.
Each server tees its output to `Q3SERVERS_LOG_DIR` (`/var/log/quake3servers`).

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
