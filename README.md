# mcp-servers

Multi-MCP-Server container based on `python:3.12-slim`.

Multiple MCP servers run in parallel within a single container, managed by `supervisord`.  
Each server is exposed via `mcp-proxy` as a Streamable HTTP endpoint (`/mcp`) and an SSE endpoint (`/sse`).

The Multi-MCP-Server container can be used locally or hosted on the internet. For public internet use with large hosted AI models such as Claude and ChatGPT, an HTTPS reverse proxy such as Nginx or similar should be used. Claude and ChatGPT only allow connections to MCP servers over HTTPS for security reasons.

## Included MCP Servers

| Port | Service | Tools | Description |
|------|---------|-------|-------------|
| 8091 | `mcp-fetch` | `fetch` | Fetch a URL and return its content as Markdown; supports chunk-based reading via `start_index` |
| 8092 | `mcp-time` | `get_current_time`, `convert_time` | Query the current time in an IANA timezone; convert times between timezones |
| 8093 | `mcp-duckduckgo` | `search`, `fetch_content` | Web search via DuckDuckGo with title, URL and snippet; fetch and parse webpage content as plain text |
| 8094 | `mcp-file-edit` | `read_file`, `write_file`, `create_file`, `delete_file`, `move_file`, `copy_file`, `list_files`, `search_files`, `replace_in_files`, `patch_file`, `list_functions`, `set_project_directory`, `git_*`, `ssh_upload`, `ssh_download`, `ssh_sync` | Comprehensive file operations, code analysis, Git integration and SSH file transfer |

## Prerequisites

- Docker + Docker Compose
- Optional: a local directory for `mcp-file-edit` (default: `/data` on the host)

## Starting

```bash
docker compose up -d --build
```

The image is built on first start (~2–5 min, as `mcp-file-edit` is compiled from GitHub).

### Setting a custom data directory

```bash
MCP_DATA_PATH=/home/user/mcp-data docker compose up -d --build
```

Or create a `.env` file in the same directory:

```env
MCP_DATA_PATH=/home/user/mcp-data
```

Without a path to a local directory, `/data` is used in isolation on the host. It is created automatically by Docker and is limited to the Docker container. After restarting the Docker container, `/data` is empty and all stored files are lost. If a path to a local directory is specified, its contents become accessible under `/data`. The Docker host system can mount remote directories into the container via `/data`. File operations can be performed read and write only within `/data`. Access beyond this path is not possible.

## Endpoints

Each server is reachable via two protocols — Streamable HTTP (`/mcp`) and SSE (`/sse`).  
Instead of `localhost`, the local IP address of the host can also be used, e.g. `http://192.168.1.100:8091/mcp`. This is useful when the container runs on a different machine in the network (e.g. NAS, server) and the MCP client accesses it from another device.

| Service | Streamable HTTP | SSE (legacy) |
|---------|----------------|--------------|
| `mcp-fetch` | `http://localhost:8091/mcp` | `http://localhost:8091/sse` |
| `mcp-time` | `http://localhost:8092/mcp` | `http://localhost:8092/sse` |
| `mcp-duckduckgo` | `http://localhost:8093/mcp` | `http://localhost:8093/sse` |
| `mcp-file-edit` | `http://localhost:8094/mcp` | `http://localhost:8094/sse` |

## Integration

### llama-ui / llama-server

llama-ui supports MCP servers with Streamable HTTP via the Settings interface.  
Add each server individually:

→ llama-ui → MCP Servers → Add New Server → Enter URL → Enable "Use llama server proxy" (if llama-server was started with `--webui-mcp-proxy`)

```
http://localhost:8091/mcp   # fetch
http://localhost:8092/mcp   # time
http://localhost:8093/mcp   # duckduckgo
http://localhost:8094/mcp   # file-edit
```

### Claude Desktop and Claude Web Client

Claude Desktop and the Claude Web Client support MCP servers with Streamable HTTP via the Settings interface.  
Add each server individually:

→ User → Settings → Customize Connectors → Plus (Add custom connectors) → Enter name → Enter URL → Add

```
https://your-domain.example.com/fetch/mcp
https://your-domain.example.com/time/mcp
https://your-domain.example.com/duckduckgo/mcp
https://your-domain.example.com/file-edit/mcp
```

Restart Claude Desktop — the MCP servers will then appear under Connectors.

> **Note:** Claude Desktop can only reach `localhost` URLs when the container runs on the same machine. For remote access, use an HTTPS reverse proxy (e.g. Nginx Proxy Manager).

### ChatGPT (Custom Connectors / GPT Actions)

ChatGPT supports MCP servers via Custom Connectors (ChatGPT Plus/Team/Enterprise) using SSE.  
Endpoints must be reachable over HTTPS — `localhost` does not work directly.

Prerequisite: a publicly reachable HTTPS URL, e.g. via Nginx Proxy Manager or Cloudflare Tunnel. To configure external MCP services, Developer Mode must be enabled first.

→ User → Settings → Apps → Advanced Settings → Developer Mode → Enable checkbox

The MCP services are then configured as follows:

→ User → Settings → Apps → Create App

```
Name: MCP tool name
Description: Explanation of the MCP tool
Connection: HTTP connection (see below)
Authentication: No authentication
Checkbox: enable (security notice)


https://your-domain.example.com/fetch/sse
https://your-domain.example.com/time/sse
https://your-domain.example.com/duckduckgo/sse
https://your-domain.example.com/file-edit/sse
```

Each server is added as a separate Custom Connector.

## Testing

Check the connection and tool listing for each server:

```bash
# mcp-fetch
curl -s -X POST http://localhost:8091/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .

# mcp-time
curl -s -X POST http://localhost:8092/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .

# mcp-duckduckgo
curl -s -X POST http://localhost:8093/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .

# mcp-file-edit
curl -s -X POST http://localhost:8094/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .
```

Each response should contain a `tools` array with the available tools of the respective server.

## Logs

```bash
# All servers
docker compose logs -f

# Individual server (stderr logs)
docker exec mcp-servers cat /tmp/mcp-fetch.err
docker exec mcp-servers cat /tmp/mcp-time.err
docker exec mcp-servers cat /tmp/mcp-duckduckgo.err
docker exec mcp-servers cat /tmp/mcp-file-edit.err
```

## Stopping

```bash
docker compose down
```

## Adding another MCP server

1. Add the package to the `pip install` list in `Dockerfile`
2. Add a new `[program:mcp-xyz]` block in `supervisord.conf` (next available port starting from 8095)
3. Add the port in `docker-compose.yml`
4. Rebuild the image: `docker compose up -d --build`
