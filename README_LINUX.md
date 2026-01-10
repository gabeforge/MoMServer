# MoM Reborn Server - Linux Setup (Python 3)

This is a Python 3 port of the Minions of Mirth private server, allowing you to host your own MoM server on Linux.

## Requirements

- Python 3.10 or higher
- Linux (tested on CachyOS/Arch)
- MoM game client files (from MoMReborn.zip)

## Quick Setup

```bash
# 1. Clone and setup
cd ~/Games/MoMServer
./setup.sh

# 2. Configure your server IP (for external access)
# Edit mud_ext/gamesettings.py and set your public IP
# Edit projects/mom.cfg if needed

# 3. Start the server
./start.sh

# 4. Stop the server
./stop.sh
```

## Server Components

The MoM server consists of multiple components:

| Component | Port | Description |
|-----------|------|-------------|
| MasterServer | 2002 | Authentication, registration, world listing |
| GMServer | 2003 | Game Master server |
| CharacterServer | - | Character data sync between worlds |
| WorldServer | 28000+ | Game world instances |

## Configuration

### Server IP (for external hosting)

Edit `mud_ext/gamesettings.py`:
```python
def override_ip_addresses():
    gamesettings.MASTERIP = 'YOUR.PUBLIC.IP.HERE'
    gamesettings.GMSERVERIP = gamesettings.MASTERIP
    gamesettings.IRC_IP = 'YOUR.PUBLIC.IP.HERE'
```

### Server Settings

Edit `projects/mom.cfg`:
```ini
[Game Settings]
Game Name = Minions of Mirth
Game Root = minions.of.mirth
Master IP = YOUR.PUBLIC.IP.HERE
Master Port = 2002
GMServer IP = YOUR.PUBLIC.IP.HERE
GMServer PORT = 2003
```

### Server Passwords

Edit `mud_ext/server/serversettings.py` to change default passwords.

## Creating a World

After starting the server:
```bash
source venv/bin/activate
python3 WorldManager.py gameconfig=mom.cfg
```

## Client Configuration

Players connecting to your server need to edit their `mud/gamesettings.py`:
```python
MASTERIP = 'YOUR.SERVER.IP'
GMSERVERIP = MASTERIP
IRC_IP = 'YOUR.SERVER.IP'
PATCH_URL = 'http://YOUR.SERVER.IP'
```

## Firewall Ports

Open these ports on your firewall:
- 2002/tcp - Master Server
- 2003/tcp - GM Server
- 28000+/tcp - World Servers

## Logs

Server logs are in `./logs/`:
- `MasterServer.log`
- `GMServer.log`
- `CharacterServer.log`

## Troubleshooting

### Server won't start
- Check Python version: `python3 --version` (needs 3.10+)
- Reinstall deps: `source venv/bin/activate && pip install -r requirements.txt`

### Clients can't connect
- Verify firewall ports are open
- Check server IP configuration in both server and client

## Credits

- Original game: Prairie Games, Inc.
- TMMOKit: Prairie Games open source release
- MoM Reborn community for preserving the game
- Python 3 port: Community contribution
