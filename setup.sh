#!/bin/bash
# MoM Reborn Server Setup Script for Linux
# Requires Python 3.10+

set -e
cd "$(dirname "$0")"

echo "=== MoM Reborn Server Setup ==="
echo ""

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $PYTHON_VERSION"

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate and install dependencies
echo "Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create directories
mkdir -p data/master data/character logs serverconfig

# Create databases if they don't exist
if [ ! -f "data/master/master.db" ]; then
    echo "Creating Master Database..."
    python3 -c "
import sys
sys.path.insert(0, '.')
from mud_ext.masterserver.createdb import main
main()
"
fi

if [ ! -f "data/character/character.db" ]; then
    echo "Creating Character Database..."
    python3 -c "
import sys
sys.path.insert(0, '.')
from mud_ext.characterserver.createdb import ConvertWorldDBToCharacterDB
ConvertWorldDBToCharacterDB()
"
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "To start the server:"
echo "  ./start.sh"
echo ""
echo "To configure your server IP, edit:"
echo "  mud_ext/gamesettings.py"
echo "  projects/mom.cfg"
