#!/bin/bash
# create_certs.sh
# Script para gerar certificados e criar secret sqfaas-files por ambiente

set -e

AMBIENTE=$1
SAN_FILE=$2
CERTS_DIR=$3

if [ -z "$AMBIENTE" ] || [ -z "$SAN_FILE" ] || [ -z "$CERTS_DIR" ]; then
  echo "[ERRO] Uso: $0 <ambiente> <san.cnf> <certs_dir>"
  exit 1
fi

mkdir -p "$CERTS_DIR/tmp-$AMBIENTE"

echo "[INFO] Gerando certificados para o ambiente: $AMBIENTE"

# Gerar certificado autoassinado
openssl req -newkey rsa:2048 -nodes -keyout "$CERTS_DIR/tmp-$AMBIENTE/server.key" \
  -x509 -days 365 -out "$CERTS_DIR/tmp-$AMBIENTE/server.crt" -config "$SAN_FILE"

# Gerar PKCS12
PKCS12_FILE="$CERTS_DIR/tmp-$AMBIENTE/server.p12"
openssl pkcs12 -export -in "$CERTS_DIR/tmp-$AMBIENTE/server.crt" \
  -inkey "$CERTS_DIR/tmp-$AMBIENTE/server.key" \
  -out "$PKCS12_FILE" -password pass:changeit

# Criar JKS exclusivo por ambiente
JKS_FILE="$CERTS_DIR/sqfaas-$AMBIENTE.jks"
keytool -importkeystore \
  -deststorepass changeit -destkeypass changeit -destkeystore "$JKS_FILE" \
  -srckeystore "$PKCS12_FILE" -srcstoretype PKCS12 -srcstorepass changeit -noprompt

echo "[OK] Certificados gerados em $CERTS_DIR"

# Criar secret sqfaas-files no namespace
echo "[INFO] Criando secret sqfaas-files para $AMBIENTE"
kubectl create secret generic sqfaas-files \
  --from-file=sqfaas.jks="$JKS_FILE" \
  --from-file=ca.crt="$CERTS_DIR/tmp-$AMBIENTE/server.crt" \
  --namespace="$AMBIENTE" --dry-run=client -o yaml | kubectl apply -f -
echo "[OK] Secret sqfaas-files criada para $AMBIENTE"

