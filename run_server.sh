#!/bin/bash

# Build and Run Docker Containers Script
# This script builds and starts the Docker containers using docker-compose

# Color codes for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    if [ "$2" -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    else
        echo -e "${RED}[ERROR]${NC} $1" >&2
        exit 1
    fi
}

# Check if we're in the correct directory (where docker-compose.yml exists)
PROJECT_DIR="legacy-start-pub"  # Should match the CLONE_DIR from setup_env.sh

if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo -e "${RED}[ERROR]${NC} docker-compose.yml not found in $PROJECT_DIR!"
    echo -e "${YELLOW}[INFO]${NC} Please ensure you're in the correct directory or run setup_env.sh first"
    exit 1
fi

# Navigate to project directory
cd "$PROJECT_DIR" || exit 1

# 1. Build Docker containers
echo -e "${YELLOW}[INFO]${NC} Building Docker containers (this may take a while)..."
docker-compose build
print_status "Docker containers built successfully" $?

# 2. Start Docker containers in detached mode
echo -e "${YELLOW}[INFO]${NC} Starting Docker containers..."
docker-compose up -d
print_status "Docker containers started successfully" $?

# 3. Show running containers
echo -e "${YELLOW}[INFO]${NC} Current container status:"
docker-compose ps

echo -e "${GREEN}[DEPLOYMENT COMPLETE]${NC} Application is running in detached mode!"
echo -e "${YELLOW}[TIP]${NC} Use 'docker-compose logs' to view application logs"