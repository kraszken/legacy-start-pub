#!/bin/bash

# Build and Run Docker Containers Script
# This script builds and starts the Docker containers using docker compose
# and sets up a cron job for automatic restarts every 4 hours

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to print status messages
print_status() {
    if [ "$2" -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    else
        echo -e "${RED}[ERROR]${NC} $1" >&2
        exit 1
    fi
}

# 1. Verify docker-compose.yml exists
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} docker-compose.yml not found at $COMPOSE_FILE!"
    echo -e "${YELLOW}[INFO]${NC} Current directory contents:"
    ls -la
    exit 1
fi

# 2. Build Docker containers
echo -e "${YELLOW}[INFO]${NC} Building Docker containers..."
if ! docker compose -f "$COMPOSE_FILE" build; then
    echo -e "${RED}[CRITICAL ERROR]${NC} Build failed with exit code $?"
    echo -e "${YELLOW}[TROUBLESHOOTING]${NC} Try running manually:"
    echo -e "  docker compose -f $COMPOSE_FILE build --no-cache --progress plain"
    exit 1
fi
print_status "Docker containers built successfully" $?

# 3. Start containers
echo -e "${YELLOW}[INFO]${NC} Starting Docker containers..."
docker compose -f "$COMPOSE_FILE" up -d
print_status "Docker containers started successfully" $?

# 4. Set up cron job for automatic restarts
echo -e "${YELLOW}[INFO]${NC} Setting up cron job for automatic restarts every 4 hours..."
CRON_JOB="0 */4 * * * docker exec etl-public /legacy/server/autorestart"
(crontab -l 2>/dev/null | grep -v "/legacy/server/autorestart"; echo "$CRON_JOB") | crontab -
print_status "Cron job for automatic restarts added successfully" $?

# 5. Show status
echo -e "${YELLOW}[INFO]${NC} Container status:"
docker compose -f "$COMPOSE_FILE" ps

echo -e "${GREEN}[DEPLOYMENT COMPLETE]${NC}"