# Lab 03 — Solution (reference)

```bash
docker run -it alpine:3.20 sh
echo "hello" > /tmp/demo.txt
exit
docker rm <container-id>

docker volume create lab03_data
docker run -it -v lab03_data:/data alpine:3.20 sh
echo "persistent" > /data/example.txt
exit
docker rm <container-id>

docker run --rm -it -v lab03_data:/data alpine:3.20 sh
ls /data
exit
```
