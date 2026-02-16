#!/bin/bash
# Revoga certificado de utilizador e gera CRL
# Uso: ./revoke_user.sh "nome_user"

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <NOME_USER>"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
USER_NAME_RAW="$1"
USER_NAME=$(echo "$USER_NAME_RAW" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
USER_CERT="$ROOT_DIR/04_user_certs/$USER_NAME/user.crt"

if [ ! -f "$USER_CERT" ]; then
    echo "Erro: certificado nao encontrado em $USER_CERT"
    exit 1
fi

pushd "$ROOT_DIR/02_inter-users" >/dev/null
openssl ca -config openssl.cnf -revoke "$USER_CERT"
openssl ca -config openssl.cnf -gencrl -out crl/inter-users.crl
popd >/dev/null

echo "--- SUCESSO ---"
echo "Certificado revogado: $USER_CERT"
echo "CRL gerada: 02_inter-users/crl/inter-users.crl"
