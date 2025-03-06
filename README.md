# docker-openconnect

**docker-openconnect** is a Docker image for running an OpenConnect Client (openconnect).

## How to Use This Image

```bash
docker run \
  --name openconnect \
  --env SERVER="bigcorp.com:8443" \
  --env USER_NAME="test" \
  --env USER_PASSWORD="test" \
  --device /dev/vhost-net:/dev/vhost-net \
  --cap-add NET_ADMIN \
  --volume ./certs:/etc/openconnect/certs \
  --rm \
  eukhlg/openconnect:dev
  ```