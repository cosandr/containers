# Thanos

Sidecar must be running with the Prometheus server, Docker nodes need to be able to connect to sidecar gRPC and Prometheus HTTP.

### Mounts

Data dirs must exist before attempting to start container, i.e.

```sh
mkdir -p data/{store-gw,compact}
```
