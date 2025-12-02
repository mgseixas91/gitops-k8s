#!/bin/bash

REPO_URL="https://github.com/mgseixas91/gitops-k8s"
BRANCH="main"
DEST_NAMESPACE="env0"

echo "🔧 Gerando Applications automaticamente..."

for DIR in $(ls -d */ 2>/dev/null); do
    APP_NAME=$(basename "$DIR")
    APP_FILE="${DIR}/app.yaml"

    echo "➡️ Criando Application para: ${APP_NAME}"

    cat <<EOF > "${APP_FILE}"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${BRANCH}
    path: apps/${APP_NAME}
    directory:
      recurse: true
  destination:
    namespace: ${DEST_NAMESPACE}
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

done

echo "✅ Finalizado! Todos os app.yaml foram criados."

