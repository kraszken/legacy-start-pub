#!/bin/bash

# Docker Installation Script
# This script checks for and installs Docker and Docker Compose
# Prerequisite: Git must be already installed for repository cloning

# Color codes for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
    if [ "$2" -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    else
        echo -e "${RED}[ERROR]${NC} $1" >&2
        exit 1
    fi
}

# 1. Check and install Docker
if ! command_exists docker; then
    echo -e "${YELLOW}[WARNING]${NC} Docker is not installed. Installing now..."
    
    # Install Docker using official Docker installation script
    echo -e "${YELLOW}[INFO]${NC} Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    
    echo -e "${YELLOW}[INFO]${NC} Running Docker installation..."
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    echo -e "${YELLOW}[INFO]${NC} Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    print_status "Docker installed successfully" $?
    
    echo -e "${YELLOW}[NOTE]${NC} You may need to log out and back in for group changes to take effect."
else
    print_status "Docker is already installed" 0
fi

# 2. Check and install Docker Compose
if ! command_exists docker-compose; then
    echo -e "${YELLOW}[WARNING]${NC} Docker Compose is not installed. Installing now..."
    
    # Install Docker Compose v2 (standalone)
    echo -e "${YELLOW}[INFO]${NC} Downloading Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    
    echo -e "${YELLOW}[INFO]${NC} Setting executable permissions..."
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_status "Docker Compose installed successfully" $?
else
    print_status "Docker Compose is already installed" 0
fi

echo -e "${GREEN}[SETUP COMPLETE]${NC} Docker environment is ready!"