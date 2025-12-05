#!/bin/bash
# create_certs.sh
# Uso: ./create_certs.sh <ambiente> <san.cnf> <certs_dir>

set -e

AMBIENTE=$1
SAN_CNF=$2
CERTS_DIR=$3

echo "[INFO] Gerando certificados para o ambiente: $AMBIENTE"

# Diretório temporário dentro do workspace
TMP_DIR="${CERTS_DIR}/tmp-${AMBIENTE}"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Arquivos de saída
JKS_FILE="${CERTS_DIR}/sqfaas.jks"
CRT_FILE="${CERTS_DIR}/ca.crt"
KEY_FILE="${CERTS_DIR}/ca.key"

# Gerar certificado autoassinado (exemplo usando OpenSSL)
# Ajuste conforme sua lógica de geração de certificado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CRT_FILE}" \
    -config "$SAN_CNF"

# Gerar PKCS12 (.p12) e converter para JKS
PKCS12_FILE="${TMP_DIR}/server.p12"
openssl pkcs12 -export -in "$CRT_FILE" -inkey "$KEY_FILE" -out "$PKCS12_FILE" -passout pass:changeit

# Converter para JKS
keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore "$JKS_FILE" \
    -srckeystore "$PKCS12_FILE" -srcstoretype PKCS12 -srcstorepass changeit -alias 1

echo "[OK] Certificados gerados em $CERTS_DIR"

