#!/bin/bash
ENV=$1

if [ -z "$ENV" ]; then
  echo "Uso: $0 <nome_do_ambiente>"
  exit 1
fi

echo "Deletando AppSet e namespace $ENV..."

# Deleta o AppSet do ArgoCD
kubectl delete applicationsets all-apps-$ENV -n argocd --ignore-not-found

# Deleta o namespace (todos os apps dentro dele serão removidos)
kubectl delete ns $ENV --wait
echo "Ambiente $ENV destruído com sucesso"

