#!/bin/bash

ENV=$1
APP_DIR=$2

if [ -z "$ENV" ] || [ -z "$APP_DIR" ]; then
  echo "Uso: $0 <ambiente> <diretorio_dos_apps>"
  exit 1
fi

GIT_REPO="https://github.com/mgseixas91/gitops-k8s.git"
TARGET_REV="main"

echo "[INFO] Criando namespace $ENV..."
kubectl create ns $ENV 2>/dev/null || echo "[INFO] Namespace $ENV já existe"

APPSET_FILE="/tmp/appset-$ENV.yaml"

echo "[INFO] Gerando AppSet em $APPSET_FILE"

cat <<EOF > $APPSET_FILE
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-apps-$ENV
  namespace: argocd
spec:
  generators:
    - matrix:
        generators:
          - list:
              elements:
                - env: $ENV
          - list:
              elements:
EOF

# Adiciona todos os apps
for APP in $(ls $APP_DIR); do
  echo "                - app: $APP" >> $APPSET_FILE
done

cat <<EOF >> $APPSET_FILE
  template:
    metadata:
      name: '{{env}}-{{app}}'
    spec:
      project: default
      source:
        repoURL: $GIT_REPO
        targetRevision: $TARGET_REV
        path: gitops-apps/apps/{{app}}/manifest
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
EOF

echo "[INFO] Aplicando AppSet..."
kubectl apply -n argocd -f $APPSET_FILE

echo "[OK] Ambiente $ENV criado com sucesso!"

