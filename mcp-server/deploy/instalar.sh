#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Despliegue del servidor MCP UNAB en una instancia EC2 (Ubuntu 22.04+).
#
#   ./deploy/instalar.sh                 # despliegue completo
#   ./deploy/instalar.sh --sin-caddy     # solo Docker + contenedor
#   DOMINIO=mcp.midominio.com ./deploy/instalar.sh
#
# Requisitos en el security group: TCP 22 (SSH), 80 y 443 (HTTPS de Caddy).
# El puerto 9000 queda escuchando solo en 127.0.0.1.
# ---------------------------------------------------------------------------
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMINIO="${DOMINIO:-54-211-28-77.sslip.io}"
CON_CADDY=1
[[ "${1:-}" == "--sin-caddy" ]] && CON_CADDY=0

cd "$DIR"

paso() { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }

paso "1/6 Comprobando .env"
if [[ ! -f .env ]]; then
	echo "Falta $DIR/.env — cópialo de .env.example y completa los valores." >&2
	exit 1
fi
if grep -q 'PENDIENTE' .env; then
	echo "El .env todavía tiene valores PENDIENTE (base de datos)." >&2
	echo "Complétalos antes de desplegar." >&2
	exit 1
fi
chmod 600 .env

paso "2/6 Instalando Docker y Caddy"
if ! command -v docker >/dev/null; then
	sudo apt-get update -qq
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io docker-compose-v2
	sudo systemctl enable --now docker
	sudo usermod -aG docker "$USER" || true
fi
if (( CON_CADDY )) && ! command -v caddy >/dev/null; then
	sudo apt-get update -qq
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq caddy
fi
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

paso "3/6 Construyendo la imagen"
$DOCKER compose build

paso "4/6 Levantando el contenedor MCP"
$DOCKER compose up -d

paso "5/6 Esperando /health"
for i in $(seq 1 45); do
	if curl -fsS http://127.0.0.1:9000/health >/dev/null 2>&1; then
		curl -fsS http://127.0.0.1:9000/health; echo
		break
	fi
	sleep 2
	if [[ $i -eq 45 ]]; then
		echo "El contenedor no respondió. Logs:" >&2
		$DOCKER compose logs --tail 40 >&2
		exit 1
	fi
done

if (( CON_CADDY )); then
	paso "6/6 Configurando Caddy para $DOMINIO"
	sed "s/54-211-28-77\.sslip\.io/$DOMINIO/" deploy/Caddyfile | sudo tee /etc/caddy/Caddyfile >/dev/null
	sudo mkdir -p /var/log/caddy
	sudo chown caddy:caddy /var/log/caddy 2>/dev/null || true
	sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
	sudo systemctl enable --now caddy
	sudo systemctl reload caddy
	sleep 5
	echo "-- comprobando HTTPS"
	curl -fsS "https://$DOMINIO/health" && echo
	echo
	echo "Endpoint MCP: https://$DOMINIO/mcp"
else
	paso "6/6 Caddy omitido"
	echo "Endpoint local: http://127.0.0.1:9000/mcp"
fi

paso "Listo"
$DOCKER compose ps
