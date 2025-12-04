#!/bin/bash
ENV=$1

if [ -z "$ENV" ]; then
  echo "Uso: $0 <nome_do_ambiente>"
  exit 1
fi

echo "Rodando testes para ambiente $ENV..."

# Exemplo apontando para o BFF principal, pode expandir para outros apps
APP_URL="http://bff-callback.${ENV}.svc.cluster.local:8080"
mvn test -Dapp.url=$APP_URL

