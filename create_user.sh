#!/bin/bash
# Uso: ./scripts/criar_user.sh "Nome User" "email@user.com"

if [ "$#" -ne 2 ]; then
    echo "❌ Erro: Faltam argumentos."
    echo "Uso: $0 <NOME_COMUM> <EMAIL>"
    echo "Exemplo: $0 'Joao Silva' 'joao@grupo6.com'"
    exit 1
fi

RAW_NAME=$1
EMAIL=$2
# Transforma espaços em underscores e minúsculas para o nome da pasta (ex: "Joao Silva" -> "joao_silva")
SAFE_NAME=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

# Define o caminho da pasta pessoal do user
USER_DIR="04_clients/$SAFE_NAME"

echo "--- A criar pasta para o utilizador: $SAFE_NAME ---"
mkdir -p "$USER_DIR"

echo "--- 1. A gerar chave privada ---"
openssl genrsa -out "$USER_DIR/user.key" 2048

echo "--- 2. A criar pedido (CSR) ---"
openssl req -config configs/openssl.cnf -new -sha256 \
    -key "$USER_DIR/user.key" \
    -out "$USER_DIR/user.csr" \
    -subj "/C=PT/ST=Porto/O=ISEP/CN=$RAW_NAME/emailAddress=$EMAIL"

echo "--- 3. A Intermédia assina o pedido ---"
openssl ca -config configs/openssl.cnf -extensions usr_cert \
    -days 375 -notext -md sha256 \
    -in "$USER_DIR/user.csr" \
    -out "$USER_DIR/user.crt" \
    -batch

echo "--- 4. A exportar para P12 (Para o Browser) ---"
openssl pkcs12 -export \
    -in "$USER_DIR/user.crt" \
    -inkey "$USER_DIR/user.key" \
    -certfile 02_intermediate-ca/certs/ca-chain.crt \
    -out "$USER_DIR/$SAFE_NAME.p12" \
    -passout pass:1234

echo "✅ SUCESSO!"
echo "Tudo organizado em: $USER_DIR/"
echo "Ficheiro para o browser: $USER_DIR/$SAFE_NAME.p12 (Password: 1234)"