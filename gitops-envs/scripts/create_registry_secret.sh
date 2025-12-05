#!/bin/bash
ENV=$1

if [ -z "$ENV" ]; then
  echo "Uso: $0 <env>"
  exit 1
fi

echo "🔐 Criando secret acr-secret no namespace: $ENV"

# Dados fixos
AUTH_1="dG9rZW4tZ2NwLWt1YmVybmV0ZXM6U3BDRGU2RDlOS3FVV2NhR2M5NVphNFI4S0ZsdlA3UWVET1JackY5OE1TK0FDUkIrVnNqdw=="
AUTH_2="dG9rZW4tZ2NwLWt1YmVybmV0ZXM6dW9WRC9DNFNwTGpnTGlacFJKUE1lWGN4R3c5ODJtbWxrSkFnbXpDYWJCK0FDUkJEYk00eg=="

DOMAIN_1="sinqia.azurecr.io"
DOMAIN_2="sinqiainterno.azurecr.io"

TMP_FILE="/tmp/dockerconfig-${ENV}.json"

cat <<EOF > $TMP_FILE
{
  "auths": {
    "${DOMAIN_1}": {
      "auth": "${AUTH_1}"
    },
    "${DOMAIN_2}": {
      "auth": "${AUTH_2}"
    }
  }
}
EOF

# Cria secret
kubectl create secret docker-registry acr-secret \
  --from-file=.dockerconfigjson=${TMP_FILE} \
  -n ${ENV} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret acr-secret criada no namespace ${ENV}"

