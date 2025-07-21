#!/bin/bash

# Update and Restart Docker Containers Script
# Handles code updates and container restarts without explicit building

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
        return 1
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

# 2. Update source code
echo -e "${YELLOW}[INFO]${NC} Updating source code..."
if git -C "$SCRIPT_DIR" pull; then
    print_status "Code updated successfully" 0
else
    print_status "Git pull failed - continuing with existing code" 0
fi

# 3. Stop and remove containers
echo -e "${YELLOW}[INFO]${NC} Stopping and removing containers..."
docker compose -f "$COMPOSE_FILE" down
print_status "Containers stopped and removed" $?

# 4. Clean up old image (only shows error if removal fails, not when missing)
echo -e "${YELLOW}[INFO]${NC} Removing old Docker image..."
IMAGE_NAME="legacy-start-pub-etl-stable"
if docker rmi "$IMAGE_NAME:latest" 2>/dev/null; then
    print_status "Old Docker image removed" 0
elif [ $? -eq 1 ]; then
    echo -e "${YELLOW}[INFO]${NC} No existing image to remove - proceeding"
else
    print_status "Docker image removal failed" 1
fi

# 5. Start containers (will auto-build if needed)
echo -e "${YELLOW}[INFO]${NC} Starting containers with compose..."
if docker compose -f "$COMPOSE_FILE" up -d; then
    print_status "Containers started successfully" 0
else
    print_status "Failed to start containers" 1
    exit 1
fi

# 6. Set up cron job for automatic restarts (changed to daily at 03:00 AM)
echo -e "${YELLOW}[INFO]${NC} Setting up cron job for automatic restarts daily at 03:00 AM..."
CRON_JOB="0 3 * * * docker exec etl-public /legacy/server/autorestart"

# Create temporary cron file
TMP_CRON=$(mktemp)
crontab -l 2>/dev/null | grep -v "/legacy/server/autorestart" > "$TMP_CRON"
echo "$CRON_JOB" >> "$TMP_CRON"

if crontab "$TMP_CRON"; then
    print_status "Cron job for automatic restarts added successfully" 0
    rm -f "$TMP_CRON"
else
    print_status "Failed to update cron jobs" 1
    rm -f "$TMP_CRON"
    exit 1
fi

# 7. Show status and final message
echo -e "${YELLOW}[INFO]${NC} Container status:"
docker compose -f "$COMPOSE_FILE" ps

echo -e "${GREEN}[UPDATE COMPLETE]${NC}"
echo -e "Services should now be running with the latest code"
echo -e "Autorestart checks scheduled daily at 03:00 AM"