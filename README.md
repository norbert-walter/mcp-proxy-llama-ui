# mcp-servers

Multi-MCP-Server-Container auf Basis von `python:3.12-slim`.
  
Mehrere MCP-Server laufen parallel in einem einzigen Container, gesteuert durch `supervisord`.  
Jeder Server wird über `mcp-proxy` als Streamable-HTTP-Endpunkt (`/mcp`) und SSE-Endpunkt (`/sse`) erreichbar gemacht.

Der Multi-MCP-Server-Container kann lokal genutzt werden oder auch ins Internet gehostet werden. Bei einer öffentlichen Nutzung im Internet mit großen gehosteten KI-Modellen wie Claude und ChatGPT sollte ein HTTPS-Reverse-Proxy wie Nginx oder ähnlich benutzt werden. Claude und ChatGPT lassen sich aus Sicherheitsgründen nur über HTTPS-Verbindungen an den Multi-MCP-Server anbinden. 

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
MCP_DATA_PATH=/home/user/mcp-data docker compose up -d --build
```

Oder `.env`-Datei im selben Verzeichnis anlegen:

```env
MCP_DATA_PATH=/home/user/mcp-data
```

Ohne einen Pfadangabe zu einem lokalen Dateiverzeichnis wird `/data` isoliert von der Außenwelt auf dem Host verwendet. Es wird von Docker automatisch angelegt und ist auf den Docker-Container begrenzt. Nach einem Neustart des Docker-Containers ist /data leer und verliert alle gespeicherten Dateien. Verwenden Sie dagegen eine Pfadangabe zu einem lokalen Dateiverzeichnis, so wird der Verzeichnisinhalt unter /data nutzbar. Das Docker-Host-System kann entfernte Verzeichnisse über /data im Docker-Container einbinden. Datei-Operationen können lesend und schreibend nur auf /data ausgeführt werden. Darüber hinaus ist ein Zugriff nicht möglich.

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

llama-ui unterstützt MCP-Server mit Streamable HTTP über die Settings-Oberfläche.  
Jeden Server einzeln eintragen:

→ llama-ui → MCP Servers → Add New Server → URL eintragen → „Use llama server proxy" aktivieren (wenn llama-server mit `--webui-mcp-proxy` gestartet)

```
http://localhost:8091/mcp   # fetch
http://localhost:8092/mcp   # time
http://localhost:8093/mcp   # duckduckgo
http://localhost:8094/mcp   # file-edit
```

### Claude Desktop und Claude Web Client

Claude Desktop und Claude Web Client unterstützt MCP-Server mit Streamable HTTP über die Settings-Oberfläche.  
Jeden Server einzeln eintragen:

→ User → Einstellungen → Konnektoren Anpassen → Plus (Benutzerdefinierte Konnektoren hinzufügen) → Namen eintragen → URL eintragen → Hinzufügen

```
https://your-domain.example.com/fetch/mcp
https://your-domain.example.com/time/mcp
https://your-domain.example.com/duckduckgo/mcp
https://your-domain.example.com/file-edit/mcp
```

Claude Desktop neu starten — die MCP-Server erscheinen dann unter Konnektoren.

> **Hinweis:** Claude Desktop erreichr nur `localhost`-URLs, wenn der Container auf demselben Rechner läuft. Für Remotezugriff einen HTTPS-Reverse-Proxy (z.B. Nginx Proxy Manager) vorschalten.

### ChatGPT (Custom Connectors / GPT Actions)

ChatGPT unterstützt MCP-Server über Custom Connectors (ChatGPT Plus/Team/Enterprise) via SSE.  
Die Endpunkte müssen über HTTPS erreichbar sein — `localhost` funktioniert nicht direkt.

Voraussetzung: öffentlich erreichbare HTTPS-URL, z.B. via Nginx Proxy Manager oder Cloudflare Tunnel. Um externe MCP-Services konfigurieren zu können, muss der Entwicklermode aktiviert werden.

→ User → Einstellungen → Apps → Erweiterte Einstellungen → Entwicklermodus → Checkbox aktivieren

Die MCP-Services werden dann wie folgt konfiguriert:

→ User → Einstellungen → Apps → App erstellen

```
Name: MCP-Tool-Name
Beschreibung: Erklärung zum MCP-Tool
Verbindung: HTTP-Verbindung (siehe unten)
Authentifizierung: Keine Authentifizierung
Checkbox: aktivieren (Sicherheitsinfo)


https://your-domain.example.com/fetch/sse
https://your-domain.example.com/time/sse
https://your-domain.example.com/duckduckgo/sse
https://your-domain.example.com/file-edit/sse
```

Jeder Server wird als separater Custom Connector eingetragen.

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
