#!/bin/bash
# Script para criar identidade de Utilizador (PKCS#12)
# Uso: ./gen_user.sh "Nome do User" "email@grupo6.com"

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <Nome> <Email>"
    exit 1
fi

USER_NAME="$1"
USER_EMAIL="$2"
# Converter nome para formato de ficheiro (ex: João Silva -> joao_silva)
FILE_NAME=$(echo "$USER_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

echo "--- A CRIAR IDENTIDADE PARA: $USER_NAME ---"

# 1. Preparar pastas
mkdir -p 04_user_certs/$FILE_NAME
cd 04_user_certs/$FILE_NAME

# 2. Gerar Chave Privada do Utilizador
echo "1. A gerar chave privada..."
openssl genrsa -aes256 -out ${FILE_NAME}.key 2048

# 3. Gerar CSR (Pedido)
echo "2. A gerar Pedido (CSR)..."
# Nota: Apontamos para o config da INTER-USERS
openssl req -new -key ${FILE_NAME}.key -out ${FILE_NAME}.csr \
    -subj "/C=PT/ST=Porto/O=ISEP/OU=HR_Dept/CN=${USER_NAME}/emailAddress=${USER_EMAIL}"

# 4. A INTER-USERS Assina
echo "3. A Inter-Users CA vai assinar..."
cd ../../02_inter-users
openssl ca -config openssl.cnf -extensions usr_cert \
    -days 365 -notext -md sha256 \
    -in ../04_user_certs/$FILE_NAME/${FILE_NAME}.csr \
    -out ../04_user_certs/$FILE_NAME/${FILE_NAME}.crt
cd ../04_user_certs/$FILE_NAME

# 5. Empacotar tudo num PKCS#12 (.p12)
echo "4. A exportar para .p12 (Define uma password de exportação!)..."
openssl pkcs12 -export \
    -in ${FILE_NAME}.crt \
    -inkey ${FILE_NAME}.key \
    -certfile ../../02_inter-users/certs/ca-chain.crt \
    -out ${FILE_NAME}.p12

echo "--- SUCESSO ---"
echo "O ficheiro para enviar ao utilizador está em:"
echo "04_user_certs/$FILE_NAME/${FILE_NAME}.p12"