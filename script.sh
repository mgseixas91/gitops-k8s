#!/bin/bash
# add-namespace-safe.sh
# Adiciona namespace somente em manifests válidos do Kubernetes

APPS_DIR="./apps"
TARGET_NAMESPACE="env0"

add_namespace() {
    local file="$1"

    # Verifica se tem apiVersion e kind
    if ! grep -qE '^apiVersion:|^kind:' "$file"; then
        echo "Ignorando $file: não parece um recurso K8s"
        return
    fi

    # Ignora Namespace e CRD
    kind=$(yq e '.kind' "$file")
    if [[ "$kind" == "Namespace" || "$kind" == "CustomResourceDefinition" ]]; then
        echo "Ignorando $file: $kind não precisa de namespace"
        return
    fi

    # Adiciona namespace se não existir
    yq e -i "select(.metadata.namespace == null) | .metadata.namespace = \"$TARGET_NAMESPACE\"" "$file"
    echo "Namespace adicionado em $file"
}

# Processa diretórios
for dir in "$APPS_DIR"/*/; do
    [ ! -d "$dir" ] && continue
    for yaml in "$dir"*.yaml "$dir"*.yml; do
        [ ! -f "$yaml" ] && continue
        add_namespace "$yaml"
    done
done

# Processa arquivos soltos na raiz de apps/
for yaml in "$APPS_DIR"/*.yaml "$APPS_DIR"/*.yml; do
    [ ! -f "$yaml" ] && continue
    add_namespace "$yaml"
done

echo "Processamento finalizado."

