#!/bin/bash
set -e
echo "--- A INICIAR INTERMEDIATE CA: USERS ---"

if [ -f certs/inter-users.crt ] && [ -f private/inter-users.key ]; then
    echo "Inter-Users CA ja existe. A saltar criacao."
    exit 0
fi

mkdir -p certs crl newcerts private db csr
touch db/index.txt
[ ! -f db/serial ] && echo 1000 > db/serial
[ ! -f db/crlnumber ] && echo 1000 > db/crlnumber

echo "[1/3] A gerar Chave Privada..."
echo "Vai ser pedida a password da chave da Inter-Users CA."
openssl genrsa -aes256 -out private/inter-users.key 4096

echo "[2/3] A gerar o Pedido (CSR)..."
# Common Name deve ser "Grupo6 Users CA"
echo "Vai ser pedida a password da chave da Inter-Users CA."
openssl req -config openssl.cnf -new -sha256 \
    -key private/inter-users.key \
    -out csr/inter-users.csr

echo "[3/3] A pedir à ROOT CA para assinar..."
echo "Vai ser pedida a password da chave da Root CA."
cd ../01_root-ca
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in ../02_inter-users/csr/inter-users.csr \
    -out ../02_inter-users/certs/inter-users.crt
cd ../02_inter-users

cat certs/inter-users.crt ../01_root-ca/certs/root.crt > certs/ca-chain.crt
chmod 444 certs/ca-chain.crt

echo "--- SUCESSO! Intermediate Users CA Criada ---"