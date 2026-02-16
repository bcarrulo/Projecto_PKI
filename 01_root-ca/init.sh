#!/bin/bash
# Script de Inicialização da ROOT CA
# Grupo 6 - SEPDD

# 1. Parar se houver erros
set -e

echo "--- A INICIAR CONFIGURAÇÃO DA ROOT CA ---"

if [ -f certs/root.crt ] && [ -f private/root.key ]; then
    echo "Root CA ja existe. A saltar criacao."
    exit 0
fi

echo "[1/4] A criar diretorias..."
mkdir -p certs crl newcerts private db csr

# 3. Inicializar Base de Dados (Flat File Database)
echo "[2/4] A criar base de dados do OpenSSL..."
touch db/index.txt
if [ ! -f db/serial ]; then
    echo 1000 > db/serial
fi
if [ ! -f db/crlnumber ]; then
    echo 1000 > db/crlnumber
fi

# 4. Gerar a Chave Privada da Root (4096 bits)
# -aes256: Protege a chave com palavra-passe
echo "[3/4] A gerar Chave Privada (Define uma password forte!)..."
echo "Vai ser pedida a password da chave da Root CA."
openssl genrsa -aes256 -out private/root.key 4096

# 5. Gerar o Certificado Auto-Assinado (Self-Signed)
# -config openssl.cnf: Usa a configuração local desta pasta
# -extensions v3_ca: Aplica as regras de Root CA (CA:TRUE)
# -days 7300: Validade de 20 anos
echo "[4/4] A criar Certificado Root (Responde às perguntas)..."
echo "IMPORTANTE: Em 'Common Name', escreve: Grupo6 Root CA"
echo "Se pedirem novamente, usa a mesma password da Root CA."
openssl req -config openssl.cnf \
      -key private/root.key \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/root.crt
      

# 6. Verificação Final
echo "--- CONCLUÍDO ---"
echo "Verifica os detalhes abaixo:"
openssl x509 -noout -text -in certs/root.crt | grep -E 'Subject:|Issuer:|Not Before:|Not After :|Public Key Algorithm:|RSA Public-Key:'