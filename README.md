/usr/local/bin/start_quake_servers.sh
/etc/systemd/system/quake_servers.service
/home/lanparty/Steam/steamapps/common/Quake Live Dedicated Server/start_ql_ca.sh
/home/lanparty/Steam/steamapps/common/Quake Live Dedicated Server/start_ql_ctf.sh


ToDo:

- Create GIT repo
- Installers:
    - Steam and QuakeLive Installer with minqlx support (Redis, python, etc)
    - ioQuake3 installer and dependencies
    - quake3 + pointrelease 1.32c for RA3

- Can we make ioQuake3 to work for RA3?

- Separate methods to startup servers

- Per Server Type:

    - RA3 
        - arena.cfg is not loaded! Check startup log: Error: Couldn't load arena/arena.cfg (WHYYY??)
        - Make it work with ioQuake3

    - OSP
        - Add tournament maps
        - Setup maprotation and map setup for Tournaments

    - QL CA
        - Minqlx plugins and workshop items
        - NTH: Local stats

    - QL CTF
