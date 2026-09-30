# Deployment Architecture

English | [简体中文](architecture.md)

## Target topology

The standard Docker Compose deployment runs on one customer-managed Linux host. External traffic reaches only platform-ui and platform-api; data and stream-processing components stay on internal container networks.

```text
Users / customer reverse proxy
        |
        +-- platform-ui :3000
        +-- platform-api :8050
                  |
        +---------+-------------------------------+
        | PostgreSQL | RustFS | Nessie | TuGraph |
        | Doris FE/BE | Kafka | Redis             |
        +-----------------------------------------+
                  |
        Authenticated Flink Docker gateway -> Flink job containers
```

The customer reverse proxy owns the production hostname, TLS certificates, access policy, and traffic logs. This package does not modify DNS, firewalls, or host certificates.

## Network segmentation

- `mds-frontend`: UI-to-API communication.
- `mds-data`: API access to PostgreSQL, RustFS S3, Nessie, TuGraph, and Doris.
- `mds-streaming`: API access to Kafka and Redis.
- `coomia-flink-control`: internal API-to-Flink-gateway control network.

Infrastructure services do not publish host ports by default. `docker-compose.admin.yml` is for temporary local troubleshooting only and binds to `127.0.0.1`.

## External ports

| Service | Default host port | Purpose |
|---|---:|---|
| platform-ui | 3000 | User interface |
| platform-api | 8050 | API and health checks |

Production deployments normally allow only the reverse proxy to reach these ports. The customer security baseline determines the final firewall policy.

## Persistence boundary

Compose named volumes store PostgreSQL, RustFS objects and logs, Doris, Kafka, Redis, TuGraph, and License state. Three customer directories store Flink artifacts, generated configuration, and project-scoped intake secrets. Removing containers does not remove data, but deleting named volumes causes irreversible data loss.

## Availability boundary

The standard Compose path is a single-host architecture and does not provide multi-host high availability. Host recovery depends on the customer backup and recovery process. High availability or disaster-recovery failover requires a separately designed and validated Kubernetes architecture.

## Trust boundary

The Flink Docker gateway is the only service with read-only access to the Docker socket, and it uses a dedicated control token and internal network. The Docker socket remains a privileged host interface, so host administrators, Docker group members, and the gateway token must be managed as privileged identities.
