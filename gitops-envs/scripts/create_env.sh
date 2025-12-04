#!/bin/bash
ENV=$1

if [ -z "$ENV" ]; then
  echo "Uso: $0 <nome_do_ambiente>"
  exit 1
fi

echo "Criando namespace $ENV..."
kubectl create ns $ENV || echo "Namespace $ENV já existe"

echo "Gerando AppSet dinâmico para $ENV..."

GIT_REPO="https://github.com/mgseixas91/gitops-k8s.git"
TARGET_REV="main"
APP_DIR="../../gitops-apps/apps"

# Gera o YAML do AppSet
APPSET_FILE="/tmp/appset-$ENV.yaml"
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

# Aplica o AppSet
kubectl apply -f $APPSET_FILE
echo "AppSet criado e aplicado para o ambiente $ENV"

