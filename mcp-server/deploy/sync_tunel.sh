#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Sincroniza el hostname del túnel de Cloudflare con MCP_ALLOWED_HOSTS.
#
# Los "quick tunnels" de Cloudflare generan un nombre aleatorio cada vez que
# arrancan (https://algo-random.trycloudflare.com). Este script lo lee del log,
# lo añade a la lista de hosts permitidos del servidor MCP y recrea el
# contenedor si cambió. Así el túnel se puede reiniciar sin romper el chatbot.
# ---------------------------------------------------------------------------
set -euo pipefail

LOG="${LOG:-/home/ubuntu/cloudflared-unab.log}"
BASE="${BASE:-/home/ubuntu/unab-chatbot}"
ENV_FILE="$BASE/mcp-server/.env"
SALIDA="$BASE/ENDPOINT_MCP.txt"

for _ in $(seq 1 90); do
	HOST=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" 2>/dev/null \
		| tail -1 | sed 's#https://##') || true
	[[ -n "${HOST:-}" ]] && break
	sleep 2
done

if [[ -z "${HOST:-}" ]]; then
	echo "No se encontró la URL del túnel en $LOG" >&2
	exit 1
fi

ACTUAL=$(grep '^MCP_ALLOWED_HOSTS=' "$ENV_FILE" | cut -d= -f2- || true)
if [[ "$ACTUAL" == *"$HOST"* ]]; then
	echo "Host ya permitido: $HOST"
else
	NUEVO="localhost:*,127.0.0.1:*,0.0.0.0:*,54.211.28.77:9000,54-211-28-77.sslip.io,54-211-28-77.sslip.io:*,$HOST,$HOST:*"
	sed -i "s|^MCP_ALLOWED_HOSTS=.*|MCP_ALLOWED_HOSTS=$NUEVO|" "$ENV_FILE"
	echo "MCP_ALLOWED_HOSTS actualizado con $HOST"

	if ! grep -q 'PENDIENTE' "$ENV_FILE"; then
		cd "$BASE/mcp-server"
		sudo docker compose up -d --force-recreate
	else
		echo "(el contenedor aún no arranca: falta configurar Supabase)"
	fi
fi

echo "https://$HOST" > "$SALIDA"
echo "Endpoint MCP: https://$HOST/mcp"
