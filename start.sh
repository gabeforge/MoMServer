#!/bin/bash
# MoM Reborn Server Launcher

cd "$(dirname "$0")"
source venv/bin/activate

echo "=== MoM Reborn Server ==="
echo ""

# Start server components
start_component() {
    local name=$1
    local script=$2
    echo "Starting $name..."
    python3 "$script" gameconfig=mom.cfg > "logs/${name}.log" 2>&1 &
    local pid=$!
    echo $pid > "logs/${name}.pid"
    echo "  Started (PID: $pid, Log: logs/${name}.log)"
    sleep 2
}

# Start all components
start_component "MasterServer" "MasterServer.py"
start_component "GMServer" "GMServer.py"
start_component "CharacterServer" "CharacterServer.py"

echo ""
echo "Server components started!"
echo ""
echo "To create a world, run:"
echo "  source venv/bin/activate"
echo "  python3 WorldManager.py gameconfig=mom.cfg"
echo ""
echo "To stop the server: ./stop.sh"
echo "To view logs: tail -f logs/*.log"
