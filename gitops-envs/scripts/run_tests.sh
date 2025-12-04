#!/bin/bash
ENV=$1

echo "Rodando testes para ambiente $ENV"

# Exemplo: apontando para BFF principal, pode adaptar para outros apps
APP_URL="http://bff-callback.${ENV}.svc.cluster.local:8080"
mvn test -Dapp.url=$APP_URL

