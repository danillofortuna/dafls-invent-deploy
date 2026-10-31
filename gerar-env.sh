#!/usr/bin/env sh
# Gera o .env com segredos aleatórios (só na primeira instalação; não sobrescreve um .env existente).
# Não mostra os segredos: a senha inicial do admin fica no próprio .env (INVENT_ADMIN_SENHA).
set -eu
cd "$(dirname "$0")"

# ./gerar-env.sh --localhost   publica o app só em 127.0.0.1:9000 (VPS com Cloudflare Tunnel ou outro proxy local)
case "${1:-}" in
    --localhost) INVENT_PORTA_PADRAO=127.0.0.1:9000 ;;
    "") INVENT_PORTA_PADRAO=9000 ;;
    *) echo "uso: ./gerar-env.sh [--localhost]" >&2; exit 2 ;;
esac

if [ -f .env ]; then
    echo "gerar-env: o .env já existe; nada foi alterado." >&2
    exit 1
fi
command -v openssl >/dev/null || { echo "gerar-env: instale o openssl" >&2; exit 1; }

aleatorio() { openssl rand -base64 "$1" | tr -d '\n'; }
alfanumerico() { openssl rand -hex "$1"; }

ADMIN_SENHA="$(alfanumerico 12)"
umask 077
cat > .env <<EOF
# Segredos do DAFLs Invent. Guarde uma cópia em lugar seguro: perder a INVENT_CHAVE_CIFRA torna ilegíveis as senhas
# das conexões cadastradas, e perder a INVENT_BANCO_SENHA impede o app de abrir o banco.
INVENT_BANCO_SENHA=$(alfanumerico 16)
INVENT_JWT_SEGREDO=$(aleatorio 48)
INVENT_CHAVE_CIFRA=$(aleatorio 32)
# Só cria o admin na primeira subida. Depois de trocar a senha no painel, apague esta linha.
INVENT_ADMIN_SENHA=$ADMIN_SENHA
# Porta do painel e da API. 9000 = todas as interfaces (rede local com coletores). Com proxy na mesma máquina
# (--profile https ou Cloudflare Tunnel), use 127.0.0.1:9000 para não expor o app na interface pública.
INVENT_PORTA=${INVENT_PORTA_PADRAO}
# Domínio do servidor para o HTTPS automático (só com --profile https), ex.: invent.suaempresa.com.br
INVENT_DOMINIO=
TZ=America/Sao_Paulo
# Memória do Postgres: ~25% da RAM do servidor
INVENT_PG_SHARED_BUFFERS=512MB
INVENT_PG_WORK_MEM=32MB
# Imagem do app: vazio = build local a partir do dafls_inventario.jar desta pasta.
# Do Docker Hub (privado; docker login antes): INVENT_IMAGE=danillofortuna/dafls-invent:<tag>
INVENT_IMAGE=
# Opções extras da JVM; vazio = ergonomia padrão do Java 21. Ex.: -XX:MaxRAMPercentage=50
JAVA_TOOL_OPTIONS=
EOF

echo ".env criado (permissão só do dono), com INVENT_PORTA=${INVENT_PORTA_PADRAO}."
echo "Login inicial do painel: admin, com a senha de INVENT_ADMIN_SENHA no .env (grep INVENT_ADMIN_SENHA .env)."
echo "Troque-a no primeiro acesso (menu do usuário > Trocar senha) e apague a linha do .env."
