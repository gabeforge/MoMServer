#!/bin/bash
# MoM Server Startup Script (Python 2)

BASEDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASEDIR"

PYTHON="./venv2/bin/python2 -u"  # -u for unbuffered output
LOGDIR="./logs"
mkdir -p "$LOGDIR"

# Kill any existing servers
echo "Stopping any existing servers..."
pkill -9 -f "python2.*MasterServer" 2>/dev/null
pkill -9 -f "python2.*WorldDaemon" 2>/dev/null
pkill -9 -f "python2.*WorldServer" 2>/dev/null
pkill -9 -f "python2.*CharacterServer" 2>/dev/null
sleep 2

# Start MasterServer
echo "Starting MasterServer..."
$PYTHON MasterServer.py gameconfig=mom.cfg > "$LOGDIR/MasterServer.log" 2>&1 &
echo $! > "$LOGDIR/MasterServer.pid"
sleep 3

if ! ss -tlnp | grep -q ":2002"; then
    echo "ERROR: MasterServer failed. Check $LOGDIR/MasterServer.log"
    exit 1
fi
echo "  MasterServer OK (port 2002)"

# Start WorldDaemon
echo "Starting WorldDaemon..."
$PYTHON WorldDaemon.py gameconfig=mom.cfg -worldname=PREMIUM_TheWorld -publicname="PREMIUM TheWorld" -password= > "$LOGDIR/WorldDaemon.log" 2>&1 &
echo $! > "$LOGDIR/WorldDaemon.pid"
sleep 5

if ! ss -tlnp | grep -q ":7000"; then
    echo "ERROR: WorldDaemon failed. Check $LOGDIR/WorldDaemon.log"
    exit 1
fi
echo "  WorldDaemon OK (ports 7000, 7001)"

# Start CharacterServer
echo "Starting CharacterServer..."
$PYTHON CharacterServer.py gameconfig=mom.cfg > "$LOGDIR/CharacterServer.log" 2>&1 &
echo $! > "$LOGDIR/CharacterServer.pid"
sleep 3
echo "  CharacterServer started"

# Start WorldServer
echo "Starting WorldServer..."
$PYTHON WorldServer.py gameconfig=mom.cfg -worldname=PREMIUM_TheWorld > "$LOGDIR/WorldServer_stdout.log" 2>&1 &
echo $! > "$LOGDIR/WorldServer.pid"
sleep 5

if ss -tlnp | grep -q ":28000"; then
    echo "  WorldServer OK (port 28000)"
else
    echo "  WorldServer starting (check logs)"
fi

echo ""
echo "=== Status ==="
ss -tlnp | grep -E "(2002|7000|7001|28000)"
echo ""
echo "Logs: $LOGDIR/"
echo "Stop: ./stop_server.sh"
