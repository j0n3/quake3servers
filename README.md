Work in progress...

TODO:

- Create installer symbolic lynks
    - /usr/local/games/quake3servers pointing to quake3servers repo folder
    - .service -> systemd
    - .conf -> etc
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
