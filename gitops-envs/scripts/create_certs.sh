#!/bin/bash
# create_certs.sh
# Uso: ./create_certs.sh <ENV> <SAN_CNF_PATH> <CERTS_DIR>

set -e

ENV="$1"
SAN_CNF="$2"
CERTS_DIR="$3"

if [[ -z "$ENV" || -z "$SAN_CNF" || -z "$CERTS_DIR" ]]; then
    echo "Uso: $0 <ENV> <SAN_CNF_PATH> <CERTS_DIR>"
    exit 1
fi

echo "[INFO] Gerando certificados para o ambiente: $ENV"

# Diretórios temporários
TMP_DIR=$(mktemp -d)
KEY="$TMP_DIR/server.key"
CSR="$TMP_DIR/server.csr"
CRT="$TMP_DIR/server.crt"
P12="$TMP_DIR/server.p12"
JKS="$TMP_DIR/sqfaas.jks"

# Gerar chave privada
openssl genrsa -out "$KEY" 2048

# Gerar CSR usando san.cnf
openssl req -new -key "$KEY" -out "$CSR" -config "$SAN_CNF"

# Assinar com CA existente
openssl x509 -req -in "$CSR" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
    -out "$CRT" -days 825 -sha256 -extfile "$SAN_CNF" -extensions v3_req

# Converter para PKCS12
openssl pkcs12 -export -out "$P12" -inkey "$KEY" -in "$CRT" -certfile "$CERTS_DIR/ca.crt" \
    -name sqfaas -passout pass:demosys

# Importar no Java Keystore
keytool -importkeystore -deststorepass demosys -destkeypass demosys -destkeystore "$JKS" \
    -srckeystore "$P12" -srcstoretype PKCS12 -srcstorepass demosys -alias sqfaas

# Importar CA no JKS
keytool -import -trustcacerts -alias root -file "$CERTS_DIR/ca.crt" -keystore "$JKS" -storepass demosys -noprompt

# Criar Secret Kubernetes
kubectl create secret generic secrets-files \
    --from-file=sqfaas.jks="$JKS" \
    --from-file=ca.crt="$CERTS_DIR/ca.crt" \
    --namespace="$ENV" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Certificados e Secret criados para $ENV"

# Limpeza
rm -rf "$TMP_DIR"

