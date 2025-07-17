# Legacy Start Pub Server

This guide explains how to set up and run the Legacy Start Pub server.

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
   Copy the `.env` file into the `legacy-start-pub` directory with the required configuration settings.

5. **Add Maps**  
   Place your map files in the `maps` directory within `legacy-start-pub`.

6. **Run Setup and Server Scripts**  
   Execute the following command to set up the environment and start the server:

   ```bash
   bash setup_env.sh && bash run_server.sh
   ```

7. **Server is Running**  
   The server is now active. Check the terminal for connection details or the server URL.

## Notes

- Ensure `setup_env.sh` and `run_server.sh` have executable permissions:
  ```bash
  chmod +x setup_env.sh run_server.sh
  ```
- Verify the `.env` file and `maps` directory are correctly set up.
- Check terminal output for any errors during setup or server startup.
