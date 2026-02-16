#!/bin/bash
# Revoga certificado de servidor e gera CRL
# Uso: ./revoke_server.sh "pki.grupo6.local"

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <DOMINIO>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
DOMAIN="$1"
SERVER_CERT="$ROOT_DIR/03_server_certs/$DOMAIN/${DOMAIN}.crt"

if [ ! -f "$SERVER_CERT" ]; then
    echo "Erro: certificado nao encontrado em $SERVER_CERT"
    exit 1
fi

pushd "$ROOT_DIR/02_inter-servers" >/dev/null
openssl ca -config openssl.cnf -revoke "$SERVER_CERT"
openssl ca -config openssl.cnf -gencrl -out crl/inter-servers.crl
popd >/dev/null

echo "--- SUCESSO ---"
echo "Certificado revogado: $SERVER_CERT"
echo "CRL gerada: 02_inter-servers/crl/inter-servers.crl"
