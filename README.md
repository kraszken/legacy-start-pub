# ET:Legacy Public Server setup

This guide explains how to set up and run the ET:Legacy Public Server using Docker.

## Setup Instructions

1. **Install Git**  
   Install Git using your package manager. For Debian/Ubuntu-based systems, run:

   ```bash
   sudo apt update && sudo apt install git
   ```

   For other distributions, use the appropriate package manager (e.g., `yum install git` for CentOS/RHEL, `dnf install git` for Fedora, or `pacman -S git` for Arch).

2. **Clone the Repository**  
   Clone the repository with:

   ```bash
   git clone https://github.com/kraszken/legacy-start-pub.git
   ```

3. **Navigate to the Directory**  
   Enter the project directory:

   ```bash
   cd legacy-start-pub
   ```

4. **Copy the .env File**  
   Copy the `.env` file into the `legacy-start-pub` directory with required settings (e.g., `RCONPASSWORD`, `WATCHTOWER_API_TOKEN`).

5. **Add Maps**  
   Place your map files in the `maps` directory within `legacy-start-pub`.

6. **Run Setup and Server Scripts**  
   Execute the following command to set up the environment, build and start the server, and configure automatic restarts:

   ```bash
   bash setup_env.sh && bash run_server.sh
   ```

   Alternatively, use Docker Compose to start the server manually:

   ```bash
   docker-compose up -d
   ```

7. **Server is Running**  
   The server is now active on port 27960 (UDP). Check the terminal or `docker logs etl-public` for connection details.

## Automatic Restarts

The `run_server.sh` script sets up a cron job to run `autorestart.sh` every 4 hours, which stops the server if 2 or fewer players are connected. The `restart: unless-stopped` policy in `docker-compose.yml` restarts the server automatically.

- **Verify the Cron Job**:
  ```bash
  crontab -l
  ```
  You should see:
  ```
  0 */4 * * * docker exec etl-public /legacy/server/autorestart
  ```
- **Check Restart Logs**:
  ```bash
  docker logs etl-public
  ```

## Notes

- Ensure `setup_env.sh`, `run_server.sh`, and `/legacy/server/autorestart` have executable permissions:
  ```bash
  chmod +x setup_env.sh run_server.sh
  docker exec etl-public chmod +x /legacy/server/autorestart
  ```
- Ensure the user running `run_server.sh` is in the `docker` group:
  ```bash
  sudo usermod -aG docker $USER
  ```
  Log out and back in to apply.
- Verify the `.env` file includes `RCONPASSWORD` and `WATCHTOWER_API_TOKEN`, and the `maps` directory is set up.
- The `autorestart.sh` script stops the server only if 2 or fewer players are connected, preventing disruption to active games. The container restarts automatically due to the `restart: unless-stopped` policy.
- Watchtower integration runs `autorestart.sh` before updating the container, ensuring updates occur when player count is low.
- Check `docker logs etl-public` for errors or to confirm automatic restarts.
