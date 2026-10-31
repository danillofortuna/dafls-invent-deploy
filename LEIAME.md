# Instalação do DAFLs Invent com Docker (Linux)

Esta pasta tem tudo o que vai para o servidor: o `dafls_inventario.jar` (backend com o painel web embutido), o
`Dockerfile`, o `docker-compose.yml` (app e Postgres em containers separados; HTTPS opcional) e os scripts.

## Pré-requisitos
- Linux com Docker Engine e o plugin Compose (`docker compose version`).
- Internet na instalação (baixa as imagens `eclipse-temurin:21-jre`, `postgres:17` e, com HTTPS, `caddy:2`).
- `openssl` (para gerar os segredos).

## Instalar
```sh
sudo mkdir -p /opt/dafls-invent && sudo tar -xzf dafls-invent-instalacao.tar.gz -C /opt/dafls-invent
cd /opt/dafls-invent
./gerar-env.sh            # cria o .env com segredos aleatórios (não os mostra); --localhost = só 127.0.0.1:9000
docker compose up -d --build
docker compose logs -f app   # espere "Started InventApplication"; Ctrl+C sai do log
```
Abra `http://<IP-do-servidor>:9000/` e entre com `admin` e a senha de `INVENT_ADMIN_SENHA` no `.env`
(`grep INVENT_ADMIN_SENHA .env`). Troque a senha (menu do usuário › Trocar senha) e apague essa linha do `.env`.

Guarde uma cópia do `.env` fora do servidor: sem a `INVENT_BANCO_SENHA` o app não abre o banco, e sem a
`INVENT_CHAVE_CIFRA` as senhas das conexões cadastradas ficam ilegíveis.

## Servidor na internet (VPS): HTTPS
Sem HTTPS, login, senha e token passam abertos pela internet. Com um domínio apontando para o servidor:
1. No `.env`: `INVENT_DOMINIO=invent.suaempresa.com.br` e `INVENT_PORTA=127.0.0.1:9000` (o app deixa de responder
   direto na porta 9000; só pelo HTTPS).
2. Libere as portas 80 e 443 no firewall da VPS (e feche a 9000).
3. `docker compose --profile https up -d --build`. O Caddy tira o certificado do Let's Encrypt sozinho.
4. Painel em `https://invent.suaempresa.com.br/`; no coletor, o QR Code do login já sai com esse endereço.

Sem domínio, o acesso fica em `http://<IP>:9000/`: aceitável só para um teste curto, com senhas que não sejam
usadas em outro lugar.

## VPS com Cloudflare Tunnel (ou outro proxy já instalado no servidor)
O túnel encaminha para `http://127.0.0.1:9000`; o app só responde no localhost e o HTTPS fica com a Cloudflare.
1. `./gerar-env.sh --localhost` (grava `INVENT_PORTA=127.0.0.1:9000`; num `.env` já existente, troque a linha).
2. `docker compose up -d --build` (sem o perfil `https`: o Caddy não entra).
3. No túnel, o serviço do hostname público é `http://127.0.0.1:9000` (o cloudflared com `network_mode: host`
   alcança o localhost da VPS). O QR Code do login sai com o endereço público pelo qual o painel foi aberto.
4. Confira que nada ficou exposto: `ss -tlnp | grep -E ':9000|:5432'` deve mostrar só `127.0.0.1:9000`
   (o Postgres não publica porta).

## Imagem pronta do Docker Hub (sem jar nem build no servidor)
A imagem fica no repositório privado `danillofortuna/dafls-invent` (`linux/amd64`), com tags `<data>-<commit>` e
`latest`. No servidor, faça `docker login` uma vez e defina no `.env`:
`INVENT_IMAGE=danillofortuna/dafls-invent:<tag>` (prefira a tag fixa a `latest`). Depois:
```sh
docker compose pull app
docker compose up -d --no-deps app     # na primeira instalação: docker compose up -d
```
Sem `INVENT_IMAGE`, o compose usa a imagem local `dafls-invent:atual`, construída a partir do jar desta pasta.
Gerar e enviar uma imagem nova (no Mac, depois do `./empacotar.sh`):
```sh
TAG=$(date +%Y-%m-%d)-$(git rev-parse --short HEAD)
docker buildx build --platform linux/amd64 -t danillofortuna/dafls-invent:$TAG -t danillofortuna/dafls-invent:latest --push dist/instalacao
```

## Documentação da API (Swagger)
Desligada nesta instalação (`SPRINGDOC_API_DOCS_ENABLED` e `SPRINGDOC_SWAGGER_UI_ENABLED` = `"false"` no compose):
`/swagger-ui.html` e `/v3/api-docs` dão 404. Para ligar num ambiente de teste, troque os dois para `"true"` e rode
`docker compose up -d --no-deps app`.

## Memória e CPU
Nenhum container tem limite de CPU ou memória. A JVM usa a ergonomia padrão do Java 21: heap máximo de 1/4 da
memória visível ao container (numa VPS de 32 GB, ~8 GB; ela só ocupa o que precisa). Para ajustar depois, sem
reconstruir a imagem, defina `JAVA_TOOL_OPTIONS` no `.env` (ex.: `-XX:MaxRAMPercentage=50` ou `-Xmx4g`) e rode
`docker compose up -d app`. O log mostra `Picked up JAVA_TOOL_OPTIONS: ...` com o valor em uso (vazio = padrão).
Postgres: `INVENT_PG_SHARED_BUFFERS` (padrão 512MB) e `INVENT_PG_WORK_MEM` (padrão 32MB).

## Atualizar para uma versão nova
Faça um backup antes (`./backup.sh`). Troque o `dafls_inventario.jar` pelo novo e reconstrua **só o app**, sem
tocar no Postgres:
```sh
docker compose build app
docker compose up -d --no-deps app     # recria só o app; o banco continua rodando
docker compose logs -f app
```
O banco fica no volume `dafls-invent_dados`; as migrações rodam sozinhas na subida do app.

## Backup
```sh
./backup.sh               # backups/invent-AAAAMMDD-HHMM.dump; guarda os 30 mais recentes
```
Agende no cron (`crontab -e`): `0 23 * * * /opt/dafls-invent/backup.sh >> /opt/dafls-invent/backups/backup.log 2>&1`.
Copie os backups para fora do servidor. Restaurar (apaga o que estiver no banco):
`docker compose exec -T banco pg_restore -U invent -d invent --clean --if-exists < backups/<arquivo>.dump`.

## Comandos úteis
| Para | Comando |
|---|---|
| Ver se está no ar | `docker compose ps` |
| Log do app | `docker compose logs -f app` |
| Reiniciar o app | `docker compose restart app` |
| Parar tudo (os dados ficam) | `docker compose down` |
| Memória do Postgres | `INVENT_PG_SHARED_BUFFERS` (~25% da RAM) e `INVENT_PG_WORK_MEM` no `.env`, depois `docker compose up -d` |

Nunca rode `docker compose down -v`: o `-v` apaga o volume com o banco.
