# traefik

Install yq:
```bash
sudo add-apt-repository --yes ppa:rmescandon/yq
sudo apt install yq
```

http://127.0.0.1:8080/dashboard/

Start traefik server:
```bash
docker-compose up -d --force-recreate
```
