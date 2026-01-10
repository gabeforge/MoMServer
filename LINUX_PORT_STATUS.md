# MoMServer - Minions of Mirth Private Server Session Plan

Generated: 2026-01-05 20:45 EST
Project: `/home/alphasigmachad/Code/MoMServer`
Branch: `python2-secure`

---

## Project Overview

**Minions of Mirth** was an MMO that shut down years ago. This project revives it using the open-source **TMMOKit** (Torque MMO Kit). The server is written in Python 2.7 with Twisted for networking and SQLite for persistence.

### Architecture
```
MasterServer (port 2002)     - Authentication, account management
├── CharacterServer          - Character storage/retrieval
├── WorldDaemon (port 7000)  - World orchestration
│   └── WorldServer (port 28000) - Game simulation
└── Zone Servers (29000+)    - Individual zones (REQUIRES pytge)
```

### Critical Dependency: pytge
The `pytge.pyd` (Python-Torque Game Engine bindings) is a **Windows-only binary** compiled for Python 2.5. It's required for zone servers which handle the actual 3D game world. Without it, players can:
- Login
- Create characters
- Select characters
- But **cannot enter the game world**

---

## Accomplishments

### Bug Fixes (All Working)

| Fix | File:Line | Description |
|-----|-----------|-------------|
| `remote_transferPlayer` NoSuchMethod | `mud_ext/worlddaemon/charservices.py:179` | Added alias delegating to `remote_zoneTransferPlayer` |
| `CLUSTERNAMES` config | `mud/gamesettings.py:65` | Changed from `[[]]` to `[]` so zones load from DB |
| Zone spawning pytge check | `mud/worldserver/main.py:693-706` | Try/except around pytge import |
| `executemany` lastrowid bug | `mud/worldserver/charutil.py:205-206, 217` | Changed to `execute` for single-row inserts |
| Fake zone data for routing | `mud/worldserver/charutil.py:630-639` | Allows daemon routing without zone servers |
| Secure Twisted import | `mud_ext/*` files | Updated deprecated `cred` imports |

### Infrastructure Setup

- **Python 2.7 virtualenv**: `./venv2/` with Twisted 20.3.0, sqlobject, pysqlite
- **Start/stop scripts**: `start_server.sh`, `stop_server.sh`
- **Log directory**: `./logs/` with per-component logs

### Wine Attempt (Abandoned - 2026-01-06)

Attempted to run zone servers under Wine since `pytge.pyd` is Windows-only:
- Installed Python 2.5 at `~/.wine/drive_c/Python25/`
- Verified `import pytge` works in Wine Python 2.5
- **Result**: `pytge.Init()` crashes with page fault at 0x1E0266B4
- Crash occurs during TGE window/graphics initialization (before `-dedicated` flag is processed)
- Error: `wine: Unhandled page fault on read access to 00000004` (NULL pointer dereference)
- Wine 10.20 only supports WoW64 mode - no pure 32-bit prefix available
- Tried: null graphics driver, fake DISPLAY, `-dedicated` flag - none bypass the crash
- Root cause: TGE calls Win32 GDI functions during Init that fail in Wine's headless WoW64 mode

### TMMOKit Source Archives

Located in `./tmmokit_source/`:
- `tge152_patches.zip` - Contains pytge source code patches for TGE 1.5.2
- `tmmokit152_1_3_SP2.zip` - TMMOKit 1.3 SP2 for TGE 1.5.2
- `tge1_5_2_patches/` - Extracted patches with `engine.patch` (2.3MB of Python binding code)

### TGE 1.5.2 Source Fork (NEW - 2026-01-06)

Cloned from GitHub: `https://github.com/ldarren/tge-152-fork`
Location: `/tmp/tge-152-fork/`

**Key directories**:
```
/tmp/tge-152-fork/
├── engine/
│   ├── platformX86UNIX/     # Linux platform implementation (40+ files)
│   ├── pyTorque/            # Basic Python bindings
│   ├── mmokit-tgePython/    # Full MMO Kit Python bindings
│   ├── mmokit-rpg/          # RPG game logic (referenced by Python bindings)
│   └── afx/                 # Arcane FX support
├── mk/
│   ├── configure.mk         # Build configuration
│   ├── conf.GCC4.LINUX.mk   # Linux GCC4 settings
│   └── conf.UNIX.mk         # Unix build settings
└── VS2005/
    └── pyTorque.vcproj      # Reference for Python build configuration
```

This is a complete TGE 1.5.2 with Linux support already implemented. The main task is integrating the Python bindings into the Linux build system.

---

## Current State

### What Works (Linux)
- MasterServer starts and accepts connections
- Account registration creates accounts in `data/master/master.db`
- WorldDaemon loads world data from `data/character/character.db`
- CharacterServer handles character creation/selection
- Player can log in, create characters, select characters

### What Doesn't Work (Linux)
- **Entering game world** - requires zone servers which need pytge
- Zone servers cannot spawn without pytge.so (Linux build needed)

### Running Processes (Now)
```
wineserver, winedevice.exe, winedbg  # Lingering from Wine attempts
```
Kill with: `pkill -9 wine winedbg`

---

## Files Modified (Staged)

### Core Server Files
- `mud/gamesettings.py` - CLUSTERNAMES fix
- `mud/worldserver/main.py` - pytge skip logic, zone spawning
- `mud/worldserver/charutil.py` - Character installation fixes
- `mud/world/theworld.py` - Wine zone spawning (NEEDS REVERT)
- `mud/worlddaemon/main.py` - Import fixes
- `mud/worlddaemon/worldservices.py` - Service updates

### Extension Files (mud_ext/)
- `mud_ext/worlddaemon/charservices.py` - `remote_transferPlayer` alias
- `mud_ext/worlddaemon/main.py` - Updated imports
- `mud_ext/worlddaemon/worldservices.py` - Service updates
- `mud_ext/server/serversettings.py` - Configuration
- `mud_ext/characterserver/*.py` - Character server extensions
- `mud_ext/masterserver/main.py` - Master server extensions

---

## Remaining Tasks

### Immediate (Cleanup)
- [ ] Revert Wine zone spawning code in `mud/world/theworld.py:752-762`
- [ ] Ensure pytge skip logic is clean in `mud/worldserver/main.py`
- [ ] Kill lingering Wine processes

### Future Options

#### Option A: Windows Server
Run the full server on Windows where pytge.pyd works natively.

#### Option B: Build pytge.so for Linux (Viable Path Identified!)

**Source Code Found**: `https://github.com/ldarren/tge-152-fork`
- Complete TGE 1.5.2 source with AFX support
- Includes `platformX86UNIX/` directory with full Linux platform code
- Contains Python bindings in two locations:
  - `engine/pyTorque/` - Basic Python bindings (pytorque.cc, tgePython.cc)
  - `engine/mmokit-tgePython/` - Full MMO Kit bindings (tgePyObject.cc, tgePython.cc, tgePython.h)
- Has Makefile-based build system with GCC4.LINUX support
- Already cloned to `/tmp/tge-152-fork/`

**Build Requirements**:
- GCC/G++ (any modern version should work)
- Python 2.7 development headers (`python2.7-dev` or `python27-devel`)
- SDL 1.2 (`sdl12-compat` or `sdl`)
- OpenGL, GLU headers
- OpenAL
- libogg, libvorbis, libtheora
- freetype2
- nasm (optional, for assembly optimizations)

**Build Steps**:
1. Configure: `make -f mk/configure.mk OS=LINUX COMPILER=GCC4 BUILD=RELEASE`
2. Add Python sources to `engine/targets.torque.mk`
3. Add Python include/library paths to `mk/conf.GCC4.LINUX.mk`
4. Build: `make`
5. Link as shared library: compile `pytge.so` linking against the engine

**Challenges**:
- The `mmokit-tgePython` files reference `rpg/` paths that need to be resolved
- Need to determine if simpler `pyTorque` bindings or full `mmokit-tgePython` are needed
- May require adapting from Python 2.5 to Python 2.7 API (likely minimal changes)
- Dedicated server mode should be tested first to avoid graphics dependencies

**Estimated Effort**: Medium (days, not weeks) - the hard work of Linux porting is already done in the fork

---

## Test Account

- **Username**: `gabrielgad`
- **Character**: `Baggyarmpit` (Dwarf Barbarian)

---

## Quick Resume Commands

```bash
cd /home/alphasigmachad/Code/MoMServer

# Kill Wine leftovers
pkill -9 wine winedbg

# Stop any running servers
./stop_server.sh

# Start fresh
./start_server.sh

# Watch logs
tail -f logs/WorldDaemon.log

# Check ports
ss -tlnp | grep -E "(2002|7000|7001|28000)"
```

---

## Key File Locations

```
/home/alphasigmachad/Code/MoMServer/
├── mud/                    # Core server modules
│   ├── worldserver/        # Zone/world server logic
│   ├── worlddaemon/        # World orchestration
│   ├── characterserver/    # Character persistence
│   ├── masterserver/       # Authentication
│   └── world/              # Game world logic
├── mud_ext/                # Project-specific extensions
├── data/
│   ├── character/character.db  # World/character data
│   └── master/master.db        # Account data
├── venv2/                  # Python 2.7 virtualenv
├── logs/                   # Runtime logs
├── pytge.pyd               # Windows Python-TGE bindings
├── pytge.so                # macOS Mach-O (not Linux!)
└── start_server.sh         # Startup script

/tmp/tmmokit_dev_files/systemsoftware_development_environment/
└── Python 2.5 + dependencies for Windows (TMMOKit original)
```

---

## Documentation Links

- [TMMOKit Description](https://realmcrafter.boards.net/thread/99/started-installing-tmmokit-read-first)
- [TMMOKit Docs (Archive)](https://web.archive.org/web/20111210231923/http://www.mmoworkshop.com/trac/mom/wiki/Documentation)
- [Server Architecture v2 (Archive)](https://web.archive.org/web/20111211020107/http://www.mmoworkshop.com/trac/mom/wiki/ServerArchitecture)

---

## Notes

- The `pytge.so` in the repo is a **macOS Mach-O binary**, not Linux
- pytge.pyd requires **Python 2.5** (not 2.7) - "Library python25.dll not found"
- Server works fine for everything except entering the game world
- Wine's WoW64 mode causes TGE to crash - no pure 32-bit prefix in Wine 10.20
