Work in progress... sorry

# Quake3Servers for quake lan parties

Features:
- Starts multiple servers in a tmux session
- Supports Quake Live with minqlx, Quake 3 and ioQuake3
- Spawn new server scripts detect tmux session and attach to them or launch standalone
- Systemd service for automatic launch on startup and start/stop all of them
- Detects used port and spawn in a free one
- Spawn master server with dpmaster for q3 and ioq3

# TODO:

- Create installer symbolic links to proper locations
    - /usr/local/games/quake3servers pointing to quake3servers repo folder
    - .service -> systemd
    - .conf -> /etc
    - edit service to run launcher

- Create all the installers
    - Steam + Quakelive + minqlx + plugins + python + all other system dependencies
    - dpmaster
        - clone repo
        - build
        - create symbolic lynk to /usr/local/bin
    - Install quake3 + point release 1.32c (first it has to be 1.32b?)
        - ra3
    - Install ioquake3
        - osp
    - config files
    - extra maps
    - extra mods

- Other server mods
    - instagib
    - freeze tag
    - defrag/race
    - red rover
    - More mods for QL (requires workshop items) https://steamcommunity.com/app/282440/discussions/0/490125103624446696/

- Fixes
    - RA3 autoexec is not loaded so can't place 200-100, falling damage... :(

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
