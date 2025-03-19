# docker-openconnect

**docker-openconnect** is a Docker image for running an OpenConnect Client (openconnect).

## How to Use This Image

Connect to a server with a default user `test` and password `test`:

```bash
docker run \
  --name openconnect \
  --env SERVER="bigcorp.com:8443" \
  --env USER_NAME="test" \
  --env USER_PASSWORD="test" \
  --device /dev/vhost-net:/dev/vhost-net \
  --cap-add NET_ADMIN \
  --rm \
  eukhlg/openconnect:0.1.0
  ```
Connect to a server with a certificate:

  ```bash
docker run \
  --name openconnect \
  --env SERVER="bigcorp.com:8443" \
  --env CA_CERT="certs/ca.pem"
  --env USER_CERT="certs/client.pem"
  --env USER_PKEY="certs/key.pem"
  --device /dev/vhost-net:/dev/vhost-net \
  --cap-add NET_ADMIN \
  --volume ./certs:/etc/openconnect/certs \
  --rm \
  eukhlg/openconnect:0.1.0
  ```
