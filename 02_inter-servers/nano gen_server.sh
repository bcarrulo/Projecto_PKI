#!/bin/bash
# Script para criar certificado de Servidor (Nginx, etc)
# Uso: ./gen_server.sh "pki.grupo6.local"

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <Dominio>"
    exit 1
fi

DOMAIN="$1"
echo "--- A CRIAR CERTIFICADO PARA SERVER: $DOMAIN ---"

mkdir -p 03_server_certs/$DOMAIN
cd 03_server_certs/$DOMAIN

# 1. Chave Privada (Sem password para o Nginx arrancar sozinho!)
echo "1. A gerar chave privada (sem pass)..."
openssl genrsa -out ${DOMAIN}.key 2048

# 2. CSR
echo "2. A gerar CSR..."
openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr \
    -subj "/C=PT/ST=Porto/O=ISEP/OU=IT_Dept/CN=${DOMAIN}"

# 3. A INTER-SERVERS Assina
echo "3. A Inter-Servers CA vai assinar..."
cd ../../02_inter-servers
openssl ca -config openssl.cnf -extensions server_cert \
    -days 375 -notext -md sha256 \
    -in ../03_server_certs/$DOMAIN/${DOMAIN}.csr \
    -out ../03_server_certs/$DOMAIN/${DOMAIN}.crt
cd ../03_server_certs/$DOMAIN

# 4. Criar Full Chain (Certificado + CA Intermédia + Root)
# O Nginx precisa disto tudo junto para browsers confiarem
cat ${DOMAIN}.crt ../../02_inter-servers/certs/ca-chain.crt > fullchain.crt

echo "--- SUCESSO ---"
echo "Ficheiros prontos para o Nginx:"
echo "Chave: 03_server_certs/$DOMAIN/${DOMAIN}.key"
echo "Cert:  03_server_certs/$DOMAIN/fullchain.crt"
