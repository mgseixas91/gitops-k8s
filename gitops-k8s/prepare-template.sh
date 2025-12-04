#!/usr/bin/env bash
set -euo pipefail

# Caminhos (ajuste se necessário)
SRC="environments/env0"
TGT="environments/template"

if [ ! -d "$SRC" ]; then
  echo "Fonte $SRC não existe. Ajuste e rode novamente."
  exit 1
fi

rm -rf "$TGT"
cp -a "$SRC" "$TGT"

# Substitui 'env0' literal por placeholder __ENV__ (namespace, hosts etc)
# e substitui sufixos -env0 por -__ENV__ (para nomes de aplicações)
# aplica em todos os arquivos .yaml / .yml
find "$TGT" -type f -name "*.yaml" -o -name "*.yml" | while read -r f; do
  # backup por segurança
  cp "$f" "${f}.bak"

  # substitui occurrences:
  # - 'env0' => '__ENV__'
  # - '-env0' => '-__ENV__' (para metadata.name suffix)
  # Use sed compatível (POSIX)
  sed -E -e 's/(-env0)/-__ENV__/g' -e 's/\benv0\b/__ENV__/g' "${f}.bak" > "$f"
  rm -f "${f}.bak"
done

echo "Template criado em $TGT (placeholders __ENV__ inseridos)."
echo "Revise os arquivos do template para garantir que os placeholders estão corretos."

