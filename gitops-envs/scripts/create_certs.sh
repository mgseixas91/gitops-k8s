#!/bin/bash
set -e

ENV=$1
CERTS_DIR="${WORKSPACE}/certs"
TMP_DIR="/tmp/certs-$ENV"

if [ -z "$ENV" ]; then
  echo "Uso: $0 <nome_do_ambiente>"
  exit 1
fi

mkdir -p $TMP_DIR

# 1️⃣ Gerar san.cnf dinamicamente
SAN_TEMPLATE="$CERTS_DIR/san.cnf"
SAN_FILE="$TMP_DIR/san.cnf"
sed "s/ENV/$ENV/g" $SAN_TEMPLATE > $SAN_FILE

# 2️⃣ Gerar chave e CSR
openssl genrsa -out $TMP_DIR/server.key 2048
openssl req -new -key $TMP_DIR/server.key -out $TMP_DIR/server.csr -config $SAN_FILE

# 3️⃣ Gerar certificado assinado pelo CA
openssl x509 -req -in $TMP_DIR/server.csr -CA $CERTS_DIR/ca.crt -CAkey $CERTS_DIR/ca.key -CAcreateserial \
  -out $TMP_DIR/server.crt -days 825 -sha256 -extfile $SAN_FILE -extensions v3_req

# 4️⃣ Transformar em PKCS12
openssl pkcs12 -export -out $TMP_DIR/server.p12 -inkey $TMP_DIR/server.key -in $TMP_DIR/server.crt \
  -certfile $CERTS_DIR/ca.crt -name sqfaas -passout pass:demosys

# 5️⃣ Criar Java Keystore
keytool -importkeystore -deststorepass demosys -destkeypass demosys -destkeystore $TMP_DIR/sqfaas.jks \
  -srckeystore $TMP_DIR/server.p12 -srcstoretype PKCS12 -srcstorepass demosys -alias sqfaas

# 6️⃣ Importar CA no Keystore (opcional, se necessário)
keytool -import -trustcacerts -alias root -file $CERTS_DIR/ca.crt -keystore $TMP_DIR/sqfaas.jks -storepass demosys -noprompt

# 7️⃣ Criar secret no namespace
kubectl create secret generic secrets-files \
  --from-file=sqfaas.jks=$TMP_DIR/sqfaas.jks \
  --from-file=ca.crt=$CERTS_DIR/ca.crt \
  --namespace=$ENV \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Certificados e secret criados no namespace $ENV"

