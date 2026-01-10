# MoM Reborn Server - Dockerized
# Isolates Python 2.7 and old dependencies in a container

FROM python:2.7-slim-buster

LABEL maintainer="MoM Reborn Community"
LABEL description="Minions of Mirth Reborn Private Server"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /server

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir \
    'Twisted==10.1.0' \
    'zope.interface>=4.0,<5' \
    'pyasn1==0.4.8' \
    'pycrypto==2.6.1'

# Copy server files
COPY . .

# Create data directories
RUN mkdir -p data/master data/character logs

# Expose ports
# Master Server
EXPOSE 2002
# GM Server
EXPOSE 2003
# World Server (default)
EXPOSE 28000
# Manhole (admin)
EXPOSE 8192

# Default command
CMD ["python", "MasterServer.py", "gameconfig=mom.cfg"]
