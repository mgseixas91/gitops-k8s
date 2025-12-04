#!/bin/bash
ENV=$1

echo "Criando namespace $ENV"
kubectl create ns $ENV || echo "$ENV já existe"

echo "Aplicando AppSet para o ambiente $ENV"
# Aplica o AppSet no namespace argocd
ENV=$ENV envsubst < scripts/appset-template.yaml | kubectl apply -n argocd -f -

