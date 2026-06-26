# ============================================================
# Multi-MCP-Server Container (Option B)
# Base: python:slim (no custom ENTRYPOINT)
# supervisord starts multiple mcp-proxy instances
# ============================================================
FROM python:3.12-slim

# Install supervisor + mcp-proxy + all MCP servers
RUN pip install --no-cache-dir \
        supervisor \
        mcp-proxy \
        mcp-server-fetch \
        mcp-server-time \
        "duckduckgo-mcp-server[browser]"

# Install mcp-file-edit from GitHub (no PyPI package available)
# asyncssh depends on cryptography/cffi → temporary build tools required
# Upstream bug: empty email field in pyproject.toml breaks newer setuptools
#   → sed removes ', email = ""' before pip install
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

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisord.conf

# Expose ports for all MCP servers
EXPOSE 8091 8092 8093 8094

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
