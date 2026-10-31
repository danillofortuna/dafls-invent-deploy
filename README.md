# DAFLs Invent: arquivos de instalação com Docker

Compose, Dockerfile e scripts para instalar o DAFLs Invent num Linux com Docker. **Não há segredos aqui**: o `.env`
é gerado no próprio servidor pelo `gerar-env.sh` e fica fora do git. A imagem do app vem de um repositório privado
do Docker Hub (`docker login` necessário).

## Instalar (no servidor)
```sh
# baixe por uma tag fixa, não pela main
git clone --branch <tag> --depth 1 https://github.com/danillofortuna/dafls-invent-deploy.git /opt/apps/inventario
cd /opt/apps/inventario
docker login -u <usuario-do-docker-hub>          # access token só de leitura
./gerar-env.sh --localhost                       # .env com segredos aleatórios; app só em 127.0.0.1:9000
sed -i 's|^INVENT_IMAGE=.*|INVENT_IMAGE=danillofortuna/dafls-invent:<tag-da-imagem>|' .env
docker compose pull app
docker compose up -d
```
Sem `--localhost`, o app abre a porta 9000 em todas as interfaces (rede local com coletores). Detalhes, HTTPS,
memória, backup e atualização: [LEIAME.md](LEIAME.md).

## Atualizar os arquivos desta pasta
```sh
git fetch --tags && git checkout <tag-nova>      # o .env e backups/ ficam (estão no .gitignore)
docker compose up -d
```
