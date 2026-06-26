# Docker Terminal aufrufen und in das Arbeitsverzeichnis wechseln
cd C:\Norbert_Privat\OpenPlotter\mcp-proxy-llama-ui

# Version setzen in docker-compose.yml
->image: mcp-proxy-llama-ui:1.0.0

# Image bauen und Docker-Container starten
$env:MCP_DATA_PATH="c:/Norbert_Privat/1Wire"; docker compose up -d

# Lokales Docker Image in Remote Docker Image für Github umladen und Tag setzen
docker tag mcp-proxy-llama-ui:1.0.0 openboatprojects/mcp-proxy-llama-ui:1.0.0

# Docker Image nach DockerHub hochladen (dauert etwas)
# In Docker.Desktop die Push-Funktion (Push to Docker Hub) benutzen und Image 1.0.0 hochladen
docker push openboatprojects/mcp-proxy-llama-ui:1.0.0

