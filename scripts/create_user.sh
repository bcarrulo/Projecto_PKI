#!/bin/bash
# Uso: ./create_user.sh "Nome User" "email@user.com"

set -e

if [ "$#" -ne 2 ]; then
    echo "Erro: Faltam argumentos."
    echo "Uso: $0 <NOME_COMUM> <EMAIL>"
    echo "Exemplo: $0 'Joao Silva' 'joao@grupo6.com'"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
RAW_NAME=$1
EMAIL=$2
SAFE_NAME=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

USER_DIR="$ROOT_DIR/04_user_certs/$SAFE_NAME"

echo "--- A criar pasta para o utilizador: $SAFE_NAME ---"
mkdir -p "$USER_DIR"

echo "--- 1. A gerar chave privada ---"
openssl genrsa -out "$USER_DIR/user.key" 2048

echo "--- 2. A criar pedido (CSR) ---"
openssl req -config "$ROOT_DIR/02_inter-users/openssl.cnf" -new -sha256 \
    -key "$USER_DIR/user.key" \
    -out "$USER_DIR/user.csr" \
    -subj "/C=PT/ST=Porto/O=ISEP/CN=$RAW_NAME/emailAddress=$EMAIL"

echo "--- 3. A Inter-Users assina o pedido ---"
pushd "$ROOT_DIR/02_inter-users" >/dev/null
openssl ca -config "$ROOT_DIR/02_inter-users/openssl.cnf" -extensions usr_cert \
    -days 375 -notext -md sha256 \
    -in "$USER_DIR/user.csr" \
    -out "$USER_DIR/user.crt" \
    -batch
popd >/dev/null

echo "--- 4. A exportar para P12 (Para o Browser) ---"
while true; do
    read -r -s -p "Password do P12: " P12_PASS
    echo
    read -r -s -p "Confirma a password: " P12_PASS_CONFIRM
    echo
    if [ "$P12_PASS" = "$P12_PASS_CONFIRM" ] && [ -n "$P12_PASS" ]; then
        break
    fi
    echo "Passwords nao coincidem. Tenta de novo."
done

openssl pkcs12 -export \
    -in "$USER_DIR/user.crt" \
    -inkey "$USER_DIR/user.key" \
    -certfile "$ROOT_DIR/02_inter-users/certs/ca-chain.crt" \
    -out "$USER_DIR/$SAFE_NAME.p12" \
    -passout pass:"$P12_PASS"

echo "SUCESSO!"
echo "Tudo organizado em: $USER_DIR/"
echo "Ficheiro para o browser: $USER_DIR/$SAFE_NAME.p12"
