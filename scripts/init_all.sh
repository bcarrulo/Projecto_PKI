#!/bin/bash
# Inicializa toda a PKI (Root + Intermediates)

set -e

on_error() {
    echo "Erro: falha durante a inicializacao. Verifica os passos acima."
}

trap on_error ERR

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

if ! command -v openssl >/dev/null 2>&1; then
    echo "Erro: openssl nao encontrado no PATH."
    exit 1
fi

if [ ! -f "$ROOT_DIR/01_root-ca/init.sh" ]; then
    echo "Erro: 01_root-ca/init.sh nao encontrado."
    exit 1
fi

if [ ! -f "$ROOT_DIR/02_inter-users/init.sh" ]; then
    echo "Erro: 02_inter-users/init.sh nao encontrado."
    exit 1
fi

if [ ! -f "$ROOT_DIR/02_inter-servers/init.sh" ]; then
    echo "Erro: 02_inter-servers/init.sh nao encontrado."
    exit 1
fi

ensure_exec() {
    if [ ! -x "$1" ]; then
        chmod +x "$1" 2>/dev/null || true
    fi
}

ensure_exec "$ROOT_DIR/01_root-ca/init.sh"
ensure_exec "$ROOT_DIR/02_inter-users/init.sh"
ensure_exec "$ROOT_DIR/02_inter-servers/init.sh"

echo "--- [1/4] A preparar estrutura ---"
mkdir -p "$ROOT_DIR/01_root-ca"/{private,certs,newcerts,crl,db}
mkdir -p "$ROOT_DIR/02_inter-users"/{private,certs,newcerts,crl,csr,db}
mkdir -p "$ROOT_DIR/02_inter-servers"/{private,certs,newcerts,crl,csr,db}
mkdir -p "$ROOT_DIR/03_server_certs"
mkdir -p "$ROOT_DIR/04_user_certs"

chmod 700 "$ROOT_DIR/01_root-ca/private"
chmod 700 "$ROOT_DIR/02_inter-users/private"
chmod 700 "$ROOT_DIR/02_inter-servers/private"

[ -f "$ROOT_DIR/01_root-ca/db/index.txt" ] || touch "$ROOT_DIR/01_root-ca/db/index.txt"
[ -f "$ROOT_DIR/02_inter-users/db/index.txt" ] || touch "$ROOT_DIR/02_inter-users/db/index.txt"
[ -f "$ROOT_DIR/02_inter-servers/db/index.txt" ] || touch "$ROOT_DIR/02_inter-servers/db/index.txt"

[ -f "$ROOT_DIR/01_root-ca/db/serial" ] || echo 1000 > "$ROOT_DIR/01_root-ca/db/serial"
[ -f "$ROOT_DIR/02_inter-users/db/serial" ] || echo 1000 > "$ROOT_DIR/02_inter-users/db/serial"
[ -f "$ROOT_DIR/02_inter-servers/db/serial" ] || echo 1000 > "$ROOT_DIR/02_inter-servers/db/serial"

[ -f "$ROOT_DIR/01_root-ca/db/crlnumber" ] || echo 1000 > "$ROOT_DIR/01_root-ca/db/crlnumber"
[ -f "$ROOT_DIR/02_inter-users/db/crlnumber" ] || echo 1000 > "$ROOT_DIR/02_inter-users/db/crlnumber"
[ -f "$ROOT_DIR/02_inter-servers/db/crlnumber" ] || echo 1000 > "$ROOT_DIR/02_inter-servers/db/crlnumber"

echo "--- [2/4] A criar Root CA ---"
( cd "$ROOT_DIR/01_root-ca" && ./init.sh )

echo "--- [3/4] A criar Inter-Users CA ---"
( cd "$ROOT_DIR/02_inter-users" && ./init.sh )

echo "--- [4/4] A criar Inter-Servers CA ---"
( cd "$ROOT_DIR/02_inter-servers" && ./init.sh )

echo "--- A validar PKI ---"
missing=0

check_file() {
    if [ ! -f "$1" ]; then
        echo "Em falta: $1"
        missing=1
    fi
}

check_file "$ROOT_DIR/01_root-ca/certs/root.crt"
check_file "$ROOT_DIR/01_root-ca/private/root.key"
check_file "$ROOT_DIR/02_inter-users/certs/inter-users.crt"
check_file "$ROOT_DIR/02_inter-users/private/inter-users.key"
check_file "$ROOT_DIR/02_inter-users/certs/ca-chain.crt"
check_file "$ROOT_DIR/02_inter-servers/certs/inter-servers.crt"
check_file "$ROOT_DIR/02_inter-servers/private/inter-servers.key"
check_file "$ROOT_DIR/02_inter-servers/certs/ca-chain.crt"
check_file "$ROOT_DIR/01_root-ca/db/index.txt"
check_file "$ROOT_DIR/01_root-ca/db/serial"
check_file "$ROOT_DIR/01_root-ca/db/crlnumber"
check_file "$ROOT_DIR/02_inter-users/db/index.txt"
check_file "$ROOT_DIR/02_inter-users/db/serial"
check_file "$ROOT_DIR/02_inter-users/db/crlnumber"
check_file "$ROOT_DIR/02_inter-servers/db/index.txt"
check_file "$ROOT_DIR/02_inter-servers/db/serial"
check_file "$ROOT_DIR/02_inter-servers/db/crlnumber"

if [ "$missing" -ne 0 ]; then
    echo "Falha: ficheiros obrigatorios em falta."
    exit 1
fi

openssl verify -CAfile "$ROOT_DIR/01_root-ca/certs/root.crt" \
    "$ROOT_DIR/02_inter-users/certs/inter-users.crt" >/dev/null
openssl verify -CAfile "$ROOT_DIR/01_root-ca/certs/root.crt" \
    "$ROOT_DIR/02_inter-servers/certs/inter-servers.crt" >/dev/null

echo "--- SUCESSO: PKI inicializada e validada ---"
