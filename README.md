# traefik

Install yq:
```bash
VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/tags" | jq -r '.[2].name')
BINARY=yq_linux_amd64

sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
```

http://127.0.0.1:8080/dashboard/

Start traefik server:
```bash
docker-compose up -d --force-recreate
```
