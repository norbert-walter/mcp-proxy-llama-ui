#!/bin/sh
# Erzeugt /etc/mcp/filesystem.json aus der Umgebungsvariable MCP_DATA_PATH
# Fallback: /data

DATA_PATH="${MCP_DATA_PATH:-/data}"
echo "{\"allowed_directories\": [\"${DATA_PATH}\"]}" > /etc/mcp/filesystem.json
echo "mcp-filesystem: using directory ${DATA_PATH}"

exec /usr/local/bin/supervisord -c /etc/supervisord.conf
