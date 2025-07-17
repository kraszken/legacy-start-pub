#!/bin/bash

# Setup Environment and Clone Repository Script
# This script checks for and installs required tools (Git, Docker, Docker Compose)
# then clones a specified repository

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

# Function to install package with apt
install_with_apt() {
    echo -e "${YELLOW}[INFO]${NC} Installing $1..."
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y "$1" >/dev/null 2>&1
    return $?
}

# 1. Check and install Git
if ! command_exists git; then
    echo -e "${YELLOW}[WARNING]${NC} Git is not installed. Installing now..."
    install_with_apt git
    print_status "Git installed successfully" $?
else
    print_status "Git is already installed" 0
fi

# 2. Check and install Docker
if ! command_exists docker; then
    echo -e "${YELLOW}[WARNING]${NC} Docker is not installed. Installing now..."
    
    # Install Docker using official Docker installation script
    curl -fsSL https://get.docker.com -o get-docker.sh >/dev/null 2>&1
    sudo sh get-docker.sh >/dev/null 2>&1
    sudo usermod -aG docker $USER >/dev/null 2>&1
    rm get-docker.sh
    
    print_status "Docker installed successfully" $?
else
    print_status "Docker is already installed" 0
fi

# 3. Check and install Docker Compose
if ! command_exists docker-compose; then
    echo -e "${YELLOW}[WARNING]${NC} Docker Compose is not installed. Installing now..."
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose >/dev/null 2>&1
    sudo chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
    
    print_status "Docker Compose installed successfully" $?
else
    print_status "Docker Compose is already installed" 0
fi

# 4. Clone the repository
REPO_URL="https://github.com/kraszken/legacy-start-pub.git"  # Replace with your repo URL
CLONE_DIR="etlegacy"                               # Replace with your desired directory name

if [ -d "$CLONE_DIR" ]; then
    echo -e "${YELLOW}[WARNING]${NC} Directory $CLONE_DIR already exists. Pulling latest changes..."
    cd "$CLONE_DIR" || exit 1
    git pull
    print_status "Repository updated successfully" $?
else
    echo -e "${YELLOW}[INFO]${NC} Cloning repository $REPO_URL..."
    git clone "$REPO_URL" "$CLONE_DIR"
    print_status "Repository cloned successfully" $?
fi

echo -e "${GREEN}[SETUP COMPLETE]${NC} Environment is ready!"