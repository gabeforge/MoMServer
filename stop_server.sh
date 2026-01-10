#!/bin/bash
# Stop MoM Server

cd "$(dirname "$0")"

echo "Stopping MoM Server..."

# Stop by PID files
for pidfile in logs/*.pid; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        name=$(basename "$pidfile" .pid)
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Stopping $name (PID: $pid)..."
            kill "$pid" 2>/dev/null
        fi
        rm -f "$pidfile"
    fi
done

# Kill any strays
sleep 1
pkill -f "python2.*MasterServer" 2>/dev/null
pkill -f "python2.*WorldDaemon" 2>/dev/null
pkill -f "python2.*WorldServer" 2>/dev/null
pkill -f "python2.*CharacterServer" 2>/dev/null

echo "Server stopped."
