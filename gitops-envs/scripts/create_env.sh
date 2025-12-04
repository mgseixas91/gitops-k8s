#!/bin/bash
ENV=$1

echo "Criando namespace $ENV"
kubectl create ns $ENV || echo "$ENV já existe"

echo "Aplicando AppSet para o ambiente $ENV"
# Cria AppSet temporário apontando para esse ambiente
envsubst < scripts/appset-template.yaml | kubectl apply -f -

