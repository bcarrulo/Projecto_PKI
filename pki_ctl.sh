#!/bin/bash
# Simple PKI control panel (menu)

set -e

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_DIR="$ROOT_DIR/scripts"

require_exec() {
    if [ ! -x "$1" ]; then
        chmod +x "$1" 2>/dev/null || true
    fi
}

ensure_scripts_exec() {
    require_exec "$SCRIPT_DIR/init_all.sh"
    require_exec "$SCRIPT_DIR/create_user.sh"
    require_exec "$SCRIPT_DIR/create_server.sh"
    require_exec "$SCRIPT_DIR/revoke_user.sh"
    require_exec "$SCRIPT_DIR/revoke_server.sh"
}

pause() {
    echo
    read -r -p "Press Enter to continue..."
}

show_status() {
    echo "--- PKI Status ---"
    echo "Root CA:"
    if [ -f "$ROOT_DIR/01_root-ca/certs/root.crt" ]; then
        openssl x509 -noout -subject -issuer -dates -in "$ROOT_DIR/01_root-ca/certs/root.crt"
    else
        echo "  Missing root cert"
    fi
    echo
    echo "Inter-Users CA:"
    if [ -f "$ROOT_DIR/02_inter-users/certs/inter-users.crt" ]; then
        openssl x509 -noout -subject -issuer -dates -in "$ROOT_DIR/02_inter-users/certs/inter-users.crt"
    else
        echo "  Missing inter-users cert"
    fi
    echo
    echo "Inter-Servers CA:"
    if [ -f "$ROOT_DIR/02_inter-servers/certs/inter-servers.crt" ]; then
        openssl x509 -noout -subject -issuer -dates -in "$ROOT_DIR/02_inter-servers/certs/inter-servers.crt"
    else
        echo "  Missing inter-servers cert"
    fi
}

health_check() {
    echo "--- PKI Health Check ---"
    missing=0

    check_file() {
        if [ ! -f "$1" ]; then
            echo "Missing: $1"
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
        echo "Health check: FAIL (missing files)"
        return 1
    fi

    openssl verify -CAfile "$ROOT_DIR/01_root-ca/certs/root.crt" \
        "$ROOT_DIR/02_inter-users/certs/inter-users.crt" >/dev/null
    openssl verify -CAfile "$ROOT_DIR/01_root-ca/certs/root.crt" \
        "$ROOT_DIR/02_inter-servers/certs/inter-servers.crt" >/dev/null

    echo "Health check: OK"
}

list_issued() {
    echo "--- Issued Certificates ---"
    if [ -f "$ROOT_DIR/02_inter-users/db/index.txt" ]; then
        echo "Users (02_inter-users/db/index.txt):"
        grep -v '^#' "$ROOT_DIR/02_inter-users/db/index.txt" || true
    else
        echo "Users index missing"
    fi
    echo
    if [ -f "$ROOT_DIR/02_inter-servers/db/index.txt" ]; then
        echo "Servers (02_inter-servers/db/index.txt):"
        grep -v '^#' "$ROOT_DIR/02_inter-servers/db/index.txt" || true
    else
        echo "Servers index missing"
    fi
}

init_all() {
    require_exec "$SCRIPT_DIR/init_all.sh"
    "$SCRIPT_DIR/init_all.sh"
}

create_user() {
    read -r -p "User name: " NAME
    read -r -p "User email: " EMAIL
    require_exec "$SCRIPT_DIR/create_user.sh"
    "$SCRIPT_DIR/create_user.sh" "$NAME" "$EMAIL"
}

create_server() {
    read -r -p "Server domain (e.g., pki.grupo6.local): " DOMAIN
    require_exec "$SCRIPT_DIR/create_server.sh"
    "$SCRIPT_DIR/create_server.sh" "$DOMAIN"
}

revoke_user() {
    read -r -p "User name to revoke: " NAME
    require_exec "$SCRIPT_DIR/revoke_user.sh"
    "$SCRIPT_DIR/revoke_user.sh" "$NAME"
}

revoke_server() {
    read -r -p "Server domain to revoke: " DOMAIN
    require_exec "$SCRIPT_DIR/revoke_server.sh"
    "$SCRIPT_DIR/revoke_server.sh" "$DOMAIN"
}

show_menu() {
    echo
    echo "PKI Control Panel"
    echo "1) Init all PKI"
    echo "2) Status"
    echo "3) Health check"
    echo "4) List issued certs"
    echo "5) Create user cert"
    echo "6) Create server cert"
    echo "7) Revoke user cert"
    echo "8) Revoke server cert"
    echo "9) Exit"
    echo
}

while true; do
    ensure_scripts_exec
    show_menu
    read -r -p "Select an option: " CHOICE
    case "$CHOICE" in
        1) init_all; pause ;;
        2) show_status; pause ;;
        3) health_check; pause ;;
        4) list_issued; pause ;;
        5) create_user; pause ;;
        6) create_server; pause ;;
        7) revoke_user; pause ;;
        8) revoke_server; pause ;;
        9) exit 0 ;;
        *) echo "Invalid option."; pause ;;
    esac
done
