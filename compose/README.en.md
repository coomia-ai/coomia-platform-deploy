# Docker Compose Deployment

English | [简体中文](README.md)

Docker Compose is the recommended deployment path. By default, only the UI and API are exposed. PostgreSQL, RustFS object storage, Nessie, Doris, Kafka, Redis, and TuGraph remain reachable only on internal networks.

```bash
bash ../scripts/init-config.sh
vi .env
cd ..
bash install.sh compose
```

The installer validates every image RepoDigest, secret length, directory ownership, Flink JAR digest, non-root Flink UID/GID, Doris initial password, and the merged Compose configuration. See the [installation guide](../docs/getting-started.en.md) for the complete procedure.

To access infrastructure administration ports temporarily from the host, explicitly add `docker-compose.admin.yml`. Those ports bind to `127.0.0.1` only. Do not change them to `0.0.0.0` on an Internet-facing host.
