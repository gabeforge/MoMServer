#!/bin/bash
# MoM Server Docker Entrypoint
# Starts all server components in the correct order

set -e

LOGDIR="/server/logs"
mkdir -p "$LOGDIR"

# Function to wait for a port to be listening
wait_for_port() {
    local port=$1
    local timeout=${2:-30}
    local count=0

    echo "  Waiting for port $port..."
    while ! netstat -tln | grep -q ":$port "; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $timeout ]; then
            echo "  ERROR: Timeout waiting for port $port"
            return 1
        fi
    done
    echo "  Port $port is ready"
    return 0
}

# Trap to cleanup on exit
cleanup() {
    echo "Shutting down servers..."
    kill $(jobs -p) 2>/dev/null || true
    wait
    echo "All servers stopped"
}
trap cleanup SIGTERM SIGINT

echo "=========================================="
echo "  MoM Reborn Server Starting (32-bit)"
echo "=========================================="
echo ""

# Check if pytge.so exists
if [ ! -f /server/pytge.so ]; then
    echo "ERROR: pytge.so not found!"
    exit 1
fi
echo "pytge.so: $(file /server/pytge.so | cut -d: -f2)"
echo ""

# Start MasterServer
echo "[1/4] Starting MasterServer..."
python2 -u MasterServer.py gameconfig=mom.cfg > "$LOGDIR/MasterServer.log" 2>&1 &
MASTER_PID=$!

if ! wait_for_port 2002 30; then
    echo "ERROR: MasterServer failed to start"
    cat "$LOGDIR/MasterServer.log"
    exit 1
fi
echo "  MasterServer OK (PID: $MASTER_PID)"
echo ""

# Start WorldDaemon
echo "[2/4] Starting WorldDaemon..."
python2 -u WorldDaemon.py gameconfig=mom.cfg \
    -worldname=PREMIUM_TheWorld \
    -publicname="PREMIUM TheWorld" \
    -password= \
    > "$LOGDIR/WorldDaemon.log" 2>&1 &
DAEMON_PID=$!

if ! wait_for_port 7000 30; then
    echo "ERROR: WorldDaemon failed to start"
    cat "$LOGDIR/WorldDaemon.log"
    exit 1
fi
echo "  WorldDaemon OK (PID: $DAEMON_PID)"
echo ""

# Start CharacterServer
echo "[3/4] Starting CharacterServer..."
python2 -u CharacterServer.py gameconfig=mom.cfg > "$LOGDIR/CharacterServer.log" 2>&1 &
CHAR_PID=$!
sleep 3
echo "  CharacterServer started (PID: $CHAR_PID)"
echo ""

# WorldServer is spawned by WorldDaemon automatically
# Just wait for zone servers to come up
echo "[4/4] Waiting for zone servers..."
sleep 10

if netstat -tln | grep -q ":28000 "; then
    echo "  Zone server listening on port 28000"
else
    echo "  Zone servers may take time to spawn"
    echo "  Check WorldDaemon.log for details"
fi
echo ""

echo "=========================================="
echo "  All Servers Started!"
echo "=========================================="
echo ""
echo "Ports:"
netstat -tln | grep -E ":(2002|2003|7000|7001|28000)" || echo "  (checking...)"
echo ""
echo "Logs available in: $LOGDIR/"
echo "Press Ctrl+C to stop all servers"
echo ""

# Wait for any process to exit
wait -n

# If we get here, something crashed - show what happened
echo "A server process exited unexpectedly!"
exit 1
