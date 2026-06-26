# mcp-servers

Multi-MCP-Server-Container auf Basis von `python:3.12-slim`.  
Mehrere MCP-Server laufen parallel in einem einzigen Container, gesteuert durch `supervisord`.  
Jeder Server wird über `mcp-proxy` als Streamable-HTTP-Endpunkt (`/mcp`) und SSE-Endpunkt (`/sse`) erreichbar gemacht.

## Enthaltene MCP-Server

| Port | Service | Tools | Beschreibung |
|------|---------|-------|--------------|
| 8091 | `mcp-fetch` | `fetch` | URL abrufen und Inhalt als Markdown zurückgeben; unterstützt chunk-weises Lesen via `start_index` |
| 8092 | `mcp-time` | `get_current_time`, `convert_time` | Aktuelle Uhrzeit in einer IANA-Zeitzone abfragen; Zeiten zwischen Zeitzonen umrechnen |
| 8093 | `mcp-duckduckgo` | `search`, `fetch_content` | Websuche über DuckDuckGo mit Titel, URL und Snippet; Webseiteninhalt abrufen und als Text parsen |
| 8094 | `mcp-file-edit` | `read_file`, `write_file`, `create_file`, `delete_file`, `move_file`, `copy_file`, `list_files`, `search_files`, `replace_in_files`, `patch_file`, `list_functions`, `set_project_directory`, `git_*`, `ssh_upload`, `ssh_download`, `ssh_sync` | Umfassende Dateioperationen, Code-Analyse, Git-Integration und SSH-Dateitransfer |

## Voraussetzungen

- Docker + Docker Compose
- Optional: ein lokales Verzeichnis für `mcp-file-edit` (Standard: `/data` auf dem Host)

## Starten

```bash
docker compose up -d --build
```

Beim ersten Start wird das Image gebaut (~2–5 Min, da `mcp-file-edit` aus GitHub kompiliert wird).

### Eigenes Datenverzeichnis setzen

```bash
MCP_DATA_PATH=/home/norbert/mcp-data docker compose up -d --build
```

Oder `.env`-Datei im selben Verzeichnis anlegen:

```env
MCP_DATA_PATH=/home/norbert/mcp-data
```

Ohne Angabe wird `/data` auf dem Host verwendet (wird von Docker automatisch angelegt).

## Endpunkte

Jeder Server ist über zwei Protokolle erreichbar — Streamable HTTP (`/mcp`) und SSE (`/sse`).  
Anstelle von `localhost` kann auch die lokale IP-Adresse des Hosts verwendet werden, z.B. `http://192.168.1.100:8091/mcp`. Das ist sinnvoll, wenn der Container auf einem anderen Rechner im Netzwerk läuft (z.B. NAS, Server) und der MCP-Client von einem anderen Gerät darauf zugreift.

| Service | Streamable HTTP | SSE (legacy) |
|---------|----------------|--------------|
| `mcp-fetch` | `http://localhost:8091/mcp` | `http://localhost:8091/sse` |
| `mcp-time` | `http://localhost:8092/mcp` | `http://localhost:8092/sse` |
| `mcp-duckduckgo` | `http://localhost:8093/mcp` | `http://localhost:8093/sse` |
| `mcp-file-edit` | `http://localhost:8094/mcp` | `http://localhost:8094/sse` |

## Integration

### llama-ui / llama-server

llama-ui unterstützt MCP-Server über die Settings-Oberfläche.  
Jeden Server einzeln eintragen:

→ llama-ui → Settings → MCP Servers → URL eintragen → „Use llama server proxy" aktivieren (wenn llama-server mit `--webui-mcp-proxy` gestartet)

```
http://localhost:8091/mcp   # fetch
http://localhost:8092/mcp   # time
http://localhost:8093/mcp   # duckduckgo
http://localhost:8094/mcp   # file-edit
```

### Claude Desktop

In `~/.config/Claude/claude_desktop_config.json` (Linux) bzw. `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "mcp-fetch": {
      "type": "http",
      "url": "http://localhost:8091/mcp"
    },
    "mcp-time": {
      "type": "http",
      "url": "http://localhost:8092/mcp"
    },
    "mcp-duckduckgo": {
      "type": "http",
      "url": "http://localhost:8093/mcp"
    },
    "mcp-file-edit": {
      "type": "http",
      "url": "http://localhost:8094/mcp"
    }
  }
}
```

Claude Desktop neu starten — die Server erscheinen dann im Tool-Menü (Hammer-Icon).

> **Hinweis:** Claude Desktop erreichtr nur `localhost`-URLs, wenn der Container auf demselben Rechner läuft. Für Remotezugriff einen HTTPS-Reverse-Proxy (z.B. Nginx Proxy Manager) vorschalten.

### ChatGPT (Custom Connectors / GPT Actions)

ChatGPT unterstützt MCP-Server über Custom Connectors (ChatGPT Plus/Team/Enterprise).  
Die Endpunkte müssen über HTTPS erreichbar sein — `localhost` funktioniert nicht direkt.

Voraussetzung: öffentlich erreichbare HTTPS-URL, z.B. via Nginx Proxy Manager oder Cloudflare Tunnel.

→ ChatGPT → Explore GPTs → Create → Configure → Add Action → Import from URL:

```
https://your-domain.example.com/fetch/mcp
https://your-domain.example.com/time/mcp
https://your-domain.example.com/duckduckgo/mcp
https://your-domain.example.com/file-edit/mcp
```

Alternativ kann jeder Server als separater Custom Connector eingetragen werden.

## Testen

Verbindung und Tool-Listing für jeden Server prüfen:

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

Jede Antwort sollte ein `tools`-Array mit den verfügbaren Tools des jeweiligen Servers enthalten.

## Logs

```bash
# Alle Server
docker compose logs -f

# Einzelner Server (stderr-Logs)
docker exec mcp-servers cat /tmp/mcp-fetch.err
docker exec mcp-servers cat /tmp/mcp-time.err
docker exec mcp-servers cat /tmp/mcp-duckduckgo.err
docker exec mcp-servers cat /tmp/mcp-file-edit.err
```

## Stoppen

```bash
docker compose down
```

## Einen weiteren MCP-Server hinzufügen

1. Paket in `Dockerfile` zur `pip install`-Liste hinzufügen
2. Neuen `[program:mcp-xyz]`-Block in `supervisord.conf` eintragen (nächster freier Port ab 8095)
3. Port in `docker-compose.yml` ergänzen
4. Image neu bauen: `docker compose up -d --build`
