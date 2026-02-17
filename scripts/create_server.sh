#!/bin/bash
# Uso: ./create_server.sh "pki.grupo6.local"

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <DOMINIO>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
DOMAIN="$1"
SERVER_DIR="$ROOT_DIR/03_server_certs/$DOMAIN"

echo "--- A CRIAR CERTIFICADO PARA SERVER: $DOMAIN ---"

mkdir -p "$SERVER_DIR"

echo "1. A gerar chave privada (sem pass)..."
openssl genrsa -out "$SERVER_DIR/${DOMAIN}.key" 2048

echo "2. A gerar CSR..."
openssl req -new -key "$SERVER_DIR/${DOMAIN}.key" -out "$SERVER_DIR/${DOMAIN}.csr" \
    -subj "/C=PT/ST=Porto/O=ISEP/OU=IT_Dept/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"

echo "3. A Inter-Servers CA vai assinar..."
pushd "$ROOT_DIR/02_inter-servers" >/dev/null
openssl ca -config "$ROOT_DIR/02_inter-servers/openssl.cnf" -extensions server_cert \
    -days 375 -notext -md sha256 \
    -in "$SERVER_DIR/${DOMAIN}.csr" \
    -out "$SERVER_DIR/${DOMAIN}.crt" \
    -batch
popd >/dev/null

echo "4. A criar Full Chain..."
cat "$SERVER_DIR/${DOMAIN}.crt" "$ROOT_DIR/02_inter-servers/certs/ca-chain.crt" > "$SERVER_DIR/fullchain.crt"

echo "--- SUCESSO ---"
echo "Chave: 03_server_certs/$DOMAIN/${DOMAIN}.key"
echo "Cert:  03_server_certs/$DOMAIN/fullchain.crt"
