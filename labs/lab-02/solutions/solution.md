# Lab 02 — Solution (reference)

```bash
docker images
docker pull alpine:3.20
docker inspect alpine:3.20
docker history alpine:3.20

docker run -it alpine:3.20 sh
echo "temporary data" > /tmp/example.txt
exit

docker ps -a
docker rm <container-id>

docker run --rm -it alpine:3.20 sh
ls /tmp
exit
```
