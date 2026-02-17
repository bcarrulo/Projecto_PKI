#!/bin/bash
# Publica um certificado de utilizador via SFTP (blind drop + auto-destruicao)
# Uso: ./publish_user_sftp.sh "Nome User"

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <NOME_USER>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

RAW_NAME="$1"
SAFE_NAME=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
USER_DIR="$ROOT_DIR/04_user_certs/$SAFE_NAME"
USER_KEY="$USER_DIR/user.key"
USER_CRT="$USER_DIR/user.crt"
ROOT_CRT="$ROOT_DIR/01_root-ca/certs/root.crt"

if [ ! -f "$USER_KEY" ] || [ ! -f "$USER_CRT" ]; then
    echo "Erro: certificado do user nao encontrado em $USER_DIR"
    exit 1
fi

if [ ! -f "$ROOT_CRT" ]; then
    echo "Erro: root.crt nao encontrado em $ROOT_CRT"
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "Erro: openssl nao encontrado no PATH."
    exit 1
fi

if ! command -v at >/dev/null 2>&1; then
    echo "Erro: comando 'at' nao encontrado. Instala o pacote at."
    exit 1
fi

SFTP_USER="${SFTP_USER:-transfer}"
PICKUP_BASE="${PICKUP_BASE:-/transfer/pickup}"
TTL_MINUTES="${TTL_MINUTES:-30}"

P12_PASS=$(openssl rand -hex 12)
SECRET_FOLDER=$(openssl rand -hex 8)
PICKUP_PATH="$PICKUP_BASE/$SECRET_FOLDER"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

TMP_P12="$USER_DIR/${SAFE_NAME}_sftp.p12"

openssl pkcs12 -export \
    -in "$USER_CRT" \
    -inkey "$USER_KEY" \
    -certfile "$ROOT_DIR/02_inter-users/certs/ca-chain.crt" \
    -out "$TMP_P12" \
    -passout pass:"$P12_PASS"

$SUDO mkdir -p "$PICKUP_PATH"
$SUDO cp "$TMP_P12" "$PICKUP_PATH/"
$SUDO cp "$ROOT_CRT" "$PICKUP_PATH/"
$SUDO chown -R "$SFTP_USER":"$SFTP_USER" "$PICKUP_PATH"
$SUDO chmod -R 750 "$PICKUP_PATH"

rm -f "$TMP_P12"

echo "rm -rf $PICKUP_PATH" | $SUDO at now + "$TTL_MINUTES" minutes >/dev/null 2>&1

echo ""
echo "CERTIFICADO DISPONIVEL (VALIDO POR ${TTL_MINUTES} MINUTOS)"
echo "---------------------------------------------------------"
echo "Host SFTP: <IP_DA_PKI>"
echo "User: $SFTP_USER"
echo "Path: $PICKUP_PATH"
echo "Files: ${SAFE_NAME}_sftp.p12, root.crt"
echo "Password: $P12_PASS"
echo "Nota: Se for a primeira vez, instala o root.crt no sistema/browsers."
