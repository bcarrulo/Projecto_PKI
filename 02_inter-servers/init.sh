#!/bin/bash
set -e
echo "--- A INICIAR INTERMEDIATE CA: SERVERS ---"

if [ -f certs/inter-servers.crt ] && [ -f private/inter-servers.key ]; then
    echo "Inter-Servers CA ja existe. A saltar criacao."
    exit 0
fi

# 1. Criar Estrutura
mkdir -p certs crl newcerts private db csr
touch db/index.txt
[ ! -f db/serial ] && echo 1000 > db/serial
[ ! -f db/crlnumber ] && echo 1000 > db/crlnumber

# 2. Gerar Chave Privada
echo "[1/3] A gerar Chave Privada..."
echo "Vai ser pedida a password da chave da Inter-Servers CA."
openssl genrsa -aes256 -out private/inter-servers.key 4096

# 3. Gerar Pedido (CSR)
echo "[2/3] A gerar o Pedido (CSR)..."
# IMPORTANTE: Common Name deve ser "Grupo6 Servers CA"
echo "Vai ser pedida a password da chave da Inter-Servers CA."
openssl req -config openssl.cnf -new -sha256 \
    -key private/inter-servers.key \
    -out csr/inter-servers.csr

# 4. A ROOT CA ASSINA (Simulação do envio para a Root)
echo "[3/3] A pedir à ROOT CA para assinar..."
echo "Vai ser pedida a password da chave da Root CA."
cd ../01_root-ca
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in ../02_inter-servers/csr/inter-servers.csr \
    -out ../02_inter-servers/certs/inter-servers.crt
cd ../02_inter-servers

# 5. Criar a Chain (Corrente)
cat certs/inter-servers.crt ../01_root-ca/certs/root.crt > certs/ca-chain.crt
chmod 444 certs/ca-chain.crt

echo "--- SUCESSO! Intermediate Servers CA Criada ---"