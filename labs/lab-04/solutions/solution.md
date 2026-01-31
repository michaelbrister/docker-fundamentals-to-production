# Lab 04 — Solution (reference)

```bash
docker run -d --name lab04-nginx-internal nginx:1.27
docker inspect lab04-nginx-internal

docker rm -f lab04-nginx-internal

docker run -d --name lab04-nginx -p 8080:80 nginx:1.27
docker run --rm -it alpine:3.20 sh
apk add --no-cache curl
curl http://<nginx-ip>
exit

docker rm -f lab04-nginx
```
