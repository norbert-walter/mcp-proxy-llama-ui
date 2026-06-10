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

# Config für mcp-filesystem: erlaubtes Verzeichnis wird zur Laufzeit
# aus der Umgebungsvariable MCP_DATA_PATH gesetzt (siehe entrypoint.sh)
RUN mkdir -p /etc/mcp

# Entrypoint-Script: erzeugt filesystem.json aus MCP_DATA_PATH
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# supervisord-Konfiguration einbinden
COPY supervisord.conf /etc/supervisord.conf

# Ports aller MCP-Server
EXPOSE 8091 8092 8093 8094

CMD ["/entrypoint.sh"]
