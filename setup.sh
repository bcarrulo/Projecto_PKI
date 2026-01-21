#!/bin/bash

# Define a diretoria base (onde o script for corrido)
BASE_DIR=$(pwd)

echo "--- [1/4] A criar estrutura de pastas ---"
mkdir -p $BASE_DIR/01_root-ca/{private,certs,newcerts,crl,db}
mkdir -p $BASE_DIR/02_intermediate-ca/{private,certs,newcerts,crl,csr,db}
mkdir -p $BASE_DIR/03_server
mkdir -p $BASE_DIR/04_clients

echo "--- [2/4] A definir permissões seguras (chmod 700) ---"
# Apenas o root/dono pode ler as pastas private 
chmod 700 $BASE_DIR/01_root-ca/private
chmod 700 $BASE_DIR/02_intermediate-ca/private

echo "--- [3/4] A inicializar bases de dados OpenSSL ---"
# Ficheiros index.txt vazios
touch $BASE_DIR/01_root-ca/db/index.txt
touch $BASE_DIR/02_intermediate-ca/db/index.txt

# Ficheiros de número de série (serial)
echo 1000 > $BASE_DIR/01_root-ca/db/serial
echo 1000 > $BASE_DIR/02_intermediate-ca/db/serial

# Ficheiros de numeração de CRL (Revogação)
echo 1000 > $BASE_DIR/01_root-ca/db/crlnumber
echo 1000 > $BASE_DIR/02_intermediate-ca/db/crlnumber

echo "--- [4/4] Setup concluído! ---"
echo "A infraestrutura está pronta em: $BASE_DIR"