# ============================================================
# Multi-MCP-Server Container (Option B)
# Basis: python:slim (kein fremder ENTRYPOINT)
# supervisord startet mehrere mcp-proxy-Instanzen
# ============================================================
FROM python:3.12-slim

# supervisor + mcp-proxy + alle MCP-Server installieren
RUN pip install --no-cache-dir \
        supervisor \
        mcp-proxy \
        mcp-server-fetch \
        mcp-server-time \
        "duckduckgo-mcp-server[browser]" \
        mcp-filesystem

# Config für mcp-filesystem: erlaubtes Verzeichnis /data
RUN mkdir -p /etc/mcp && echo '{"allowed_directories": ["/data"]}' > /etc/mcp/filesystem.json

# supervisord-Konfiguration einbinden
COPY supervisord.conf /etc/supervisord.conf

# Ports aller MCP-Server
EXPOSE 8091 8092 8093 8094

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
