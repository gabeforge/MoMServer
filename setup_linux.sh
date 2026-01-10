#!/bin/bash
# MoM Reborn Server Setup for Linux
# Run this after installing python2: sudo pacman -S python2

set -e

echo "=== MoM Reborn Server Setup for Linux ==="

# Check for Python 2
if ! command -v python2 &> /dev/null; then
    echo "ERROR: Python 2.7 not found!"
    echo "Install with: sudo pacman -S python2"
    exit 1
fi

echo "Python 2 found: $(python2 --version 2>&1)"

# Create virtual environment directory
VENV_DIR="./venv2"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python 2 virtual environment..."
    python2 -m virtualenv "$VENV_DIR" 2>/dev/null || {
        echo "Installing virtualenv for Python 2..."
        python2 -m pip install --user virtualenv
        python2 -m virtualenv "$VENV_DIR"
    }
fi

# Activate and install dependencies
echo "Installing Python dependencies..."
source "$VENV_DIR/bin/activate"

# Install dependencies (some may need adjustments for Linux)
pip install 'Twisted==10.1.0' 2>/dev/null || pip install 'Twisted<21'
pip install 'zope.interface>=4.0,<6'
pip install 'pyasn1'
pip install 'pycryptodome'  # pycrypto replacement

echo "Dependencies installed!"

# Create data directories
mkdir -p data/master
mkdir -p data/character
mkdir -p logs

# Create databases
echo "Creating Master Database..."
python2 -c "
import sys, os
sys.path.insert(0, os.getcwd())
from mud_ext.masterserver.createdb import main
main()
"

echo "Creating Character Database..."
python2 -c "
import sys, os
sys.path.insert(0, os.getcwd())
from mud_ext.characterserver.createdb import ConvertWorldDBToCharacterDB
ConvertWorldDBToCharacterDB()
"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "To start the server, run in separate terminals:"
echo "  source venv2/bin/activate"
echo "  python2 MasterServer.py gameconfig=mom.cfg"
echo "  python2 GMServer.py gameconfig=mom.cfg"
echo "  python2 CharacterServer.py gameconfig=mom.cfg"
echo "  python2 WorldManager.py gameconfig=mom.cfg"
echo ""
echo "Or use: ./start_server.sh"
