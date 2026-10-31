#!/usr/bin/env sh
# Backup do banco em backups/invent-AAAAMMDD-HHMM.dump (formato custom do pg_dump). Para agendar, use o cron:
#   0 23 * * * /opt/dafls-invent/backup.sh >> /opt/dafls-invent/backups/backup.log 2>&1
# Restaurar (apaga o que estiver no banco):
#   docker compose exec -T banco pg_restore -U invent -d invent --clean --if-exists < backups/<arquivo>.dump
set -eu
cd "$(dirname "$0")"

mkdir -p backups
ARQUIVO="backups/invent-$(date +%Y%m%d-%H%M).dump"
docker compose exec -T banco pg_dump -U invent -Fc invent > "$ARQUIVO.parcial"
mv "$ARQUIVO.parcial" "$ARQUIVO"
echo "backup: $ARQUIVO ($(du -h "$ARQUIVO" | cut -f1))"
# guarda os 30 mais recentes
ls -1t backups/invent-*.dump | tail -n +31 | xargs -r rm -f
