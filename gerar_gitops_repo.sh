#!/bin/bash
set -e

ROOT="./gitops-k8s/environments"

echo "🧹 Removendo namespace dos manifests de TODOS ambientes..."

for ENV in $(ls $ROOT); do
    echo "➡ Ambiente: $ENV"

    for APP in $(ls $ROOT/$ENV/apps); do
        
        MANIFEST_DIR="$ROOT/$ENV/apps/$APP/manifest"

        if [ ! -d "$MANIFEST_DIR" ]; then
            echo "  ⚠ Pasta não encontrada: $MANIFEST_DIR"
            continue
        fi

        for FILE in $(ls $MANIFEST_DIR/*.yaml); do
            echo "  ✔ Limpando namespace de: $FILE"

            # Remove apenas o campo namespace
            sed -i '/namespace:/d' "$FILE"
        done
    done
done

echo
echo "✅ Todos os namespaces foram removidos corretamente!"

