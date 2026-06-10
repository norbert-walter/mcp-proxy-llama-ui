# mcp-fetch-proxy

mcp-server-fetch (Anthropic/MCP) als Streamable-HTTP-Endpunkt für llama-ui,
gepackt mit mcp-proxy (sparfenyuk).

## Starten

```bash
docker compose up -d --build
```

Beim ersten Start wird das Image gebaut (~1–2 Min).

## Endpunkt in llama-ui eintragen

```
http://localhost:8090/mcp
```

→ llama-ui → Settings → MCP Servers → URL eintragen
→ "Use llama server proxy" aktivieren (falls llama-server mit --webui-mcp-proxy gestartet)

## Testen

```bash
curl -X POST http://localhost:8090/mcp \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

Erwartete Antwort enthält das `fetch`-Tool.

## Optionen

### robots.txt ignorieren
```yaml
command: >
  --port=8090
  --sse-host=0.0.0.0
  python3 -m mcp_server_fetch --ignore-robots-txt
```

### Eigener User-Agent
```yaml
command: >
  --port=8090
  --sse-host=0.0.0.0
  python3 -m mcp_server_fetch --user-agent="MyAgent/1.0"
```

### Upstream-Proxy (z.B. Squid)
```yaml
command: >
  --port=8090
  --sse-host=0.0.0.0
  python3 -m mcp_server_fetch --proxy-url=http://proxy:3128
```

## Logs

```bash
docker compose logs -f
```

## Stoppen

```bash
docker compose down
```
