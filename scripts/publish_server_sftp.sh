#!/bin/bash
# Publica certificado de servidor via SFTP (blind drop + auto-destruicao)
# Uso: ./publish_server_sftp.sh "pki.grupo6.local"

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <DOMINIO>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

DOMAIN="$1"
SERVER_DIR="$ROOT_DIR/03_server_certs/$DOMAIN"
SERVER_KEY="$SERVER_DIR/${DOMAIN}.key"
SERVER_CHAIN="$SERVER_DIR/fullchain.crt"

if [ ! -f "$SERVER_KEY" ] || [ ! -f "$SERVER_CHAIN" ]; then
    echo "Erro: ficheiros do server nao encontrados em $SERVER_DIR"
    exit 1
fi

if ! command -v at >/dev/null 2>&1; then
    echo "Erro: comando 'at' nao encontrado. Instala o pacote at."
    exit 1
fi

SFTP_USER="${SFTP_USER:-transfer}"
PICKUP_BASE="${PICKUP_BASE:-/transfer/pickup}"
TTL_MINUTES="${TTL_MINUTES:-30}"

SECRET_FOLDER=$(openssl rand -hex 8)
PICKUP_PATH="$PICKUP_BASE/$SECRET_FOLDER"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

$SUDO mkdir -p "$PICKUP_PATH"
$SUDO cp "$SERVER_KEY" "$PICKUP_PATH/"
$SUDO cp "$SERVER_CHAIN" "$PICKUP_PATH/"
$SUDO chown -R "$SFTP_USER":"$SFTP_USER" "$PICKUP_PATH"
$SUDO chmod -R 750 "$PICKUP_PATH"

echo "rm -rf $PICKUP_PATH" | $SUDO at now + "$TTL_MINUTES" minutes >/dev/null 2>&1

echo ""
echo "CERTIFICADO DISPONIVEL (VALIDO POR ${TTL_MINUTES} MINUTOS)"
echo "---------------------------------------------------------"
echo "Host SFTP: <IP_DA_PKI>"
echo "User: $SFTP_USER"
echo "Path: $PICKUP_PATH"
echo "Files: ${DOMAIN}.key, fullchain.crt"
