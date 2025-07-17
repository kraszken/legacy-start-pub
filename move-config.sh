#!/bin/bash
# Move contents of /legacy/server/settings to /legacy/server/etmain
mv /legacy/server/settings/* /legacy/server/etmain/
# Start the server (replace with the image’s default entrypoint)
exec /legacy/server/start