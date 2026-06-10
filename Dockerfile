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
        mcp-server-time

# supervisord-Konfiguration einbinden
COPY supervisord.conf /etc/supervisord.conf

# Ports aller MCP-Server
EXPOSE 8091 8092

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
