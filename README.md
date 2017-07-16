# docker-pull-through-cache
A docker pull through cache (registry mirror)

## Start

```sh
docker-compose pull || docker-compose build
#PROXY="socks5://127.0.0.1:1080" PULL_THROUGH_CACHE_OF="https://registry-1.docker.io" docker-compose up -d
PROXY="socks5://127.0.0.1:1080" PULL_THROUGH_CACHE_OF="https://gcr.io" docker-compose up -d
```

## Test

```sh
# --registry-mirror not set
docker pull 127.0.0.1:25004/google_containers/kube-dnsmasq-amd64:1.4
#docker pull $(docker run --net=host busybox ip addr show | grep 192 | grep -Eo '([0-9]+\.){3}[0-9]+' | head -n1):25004/google_containers/kube-dnsmasq-amd64:1.4

# --registry-mirror set to http://127.0.0.1:25004
docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.4

curl http://127.0.0.1:25004/v2/_catalog
curl http://127.0.0.1:25004/v2/google_containers/kube-dnsmasq-amd64/tags/list
```


see: https://docs.docker.com/registry/recipes/mirror/  
see: https://hub.docker.com/_/registry/  
see: https://github.com/docker/distribution-library-image/
