#!/usr/bin/env sh
# Atualiza o app para outra imagem: faz o backup do banco, baixa a imagem, grava INVENT_IMAGE no .env e recria só o
# app (o banco continua rodando; as migrações rodam na subida). Rode na pasta da instalação, com sudo se o Docker exigir:
#   sudo ./atualizar.sh danillofortuna/dafls-invent:<tag>
set -eu
cd "$(dirname "$0")"

IMAGEM="${1:-}"
if ! printf '%s\n' "$IMAGEM" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9._/-]*:[a-zA-Z0-9_][a-zA-Z0-9._-]*$'; then
    echo "uso: ./atualizar.sh <imagem:tag>  (ex.: danillofortuna/dafls-invent:2026-10-31-65c5dec)" >&2
    exit 1
fi
[ -f .env ] || { echo "atualizar: .env não encontrado nesta pasta" >&2; exit 1; }

./backup.sh

# Baixa antes de mexer no .env: uma imagem errada para aqui, com a instalação intacta.
docker pull "$IMAGEM"

# O .env pode ser um link para fora da pasta: edita o arquivo real, sem trocar o link por uma cópia.
ENV_REAL="$(readlink -f .env)"
if grep -q '^INVENT_IMAGE=' "$ENV_REAL"; then
    sed -i "s|^INVENT_IMAGE=.*|INVENT_IMAGE=$IMAGEM|" "$ENV_REAL"
else
    printf 'INVENT_IMAGE=%s\n' "$IMAGEM" >> "$ENV_REAL"
fi

docker compose up -d --no-deps app
docker compose ps app
echo "atualizar: app na imagem $IMAGEM; acompanhe com: docker compose logs -f app"
