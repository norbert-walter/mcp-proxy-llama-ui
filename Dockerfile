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
        "duckduckgo-mcp-server[browser]"

# mcp-file-edit aus GitHub installieren (kein PyPI-Paket verfügbar)
# asyncssh hängt von cryptography/cffi ab → temporäre Build-Tools nötig
# Upstream-Bug: leeres email-Feld in pyproject.toml bricht neuere setuptools
#   → sed entfernt ', email = ""' vor pip install
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libffi-dev \
        libssl-dev \
    && git clone https://github.com/patrickomatik/mcp-file-edit.git /opt/mcp-file-edit \
    && sed -i 's/, email = ""//' /opt/mcp-file-edit/pyproject.toml \
    && pip install --no-cache-dir -e /opt/mcp-file-edit \
    && apt-get purge -y --auto-remove build-essential libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# supervisord-Konfiguration einbinden
COPY supervisord.conf /etc/supervisord.conf

# Ports aller MCP-Server
EXPOSE 8091 8092 8093 8094

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
