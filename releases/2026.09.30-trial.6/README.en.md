# 2026.09.30-trial.6 Application Images

English | [简体中文](README.md)

This directory records the immutable first-party application image RepoDigests for the shared public trial release.
All four images completed Linux/amd64 builds, protection checks, Critical/secret gates before push and after
RepoDigest pullback, and CycloneDX SBOM generation.

The values are in [`application-images.env`](application-images.env). They may be used as inputs for a customer
`compose/.env` or Kubernetes release configuration, but they are **not a complete deployment configuration**.
PostgreSQL, MinIO, Nessie, TuGraph, Doris, Kafka, and Redis still require immutable digests approved for the same
customer package.

Current boundary:

- All four GHCR images are Public and have passed credential-free anonymous reads by RepoDigest.
- The repository remains `PREPARED`; formal installation is not allowed.
- The Docker Compose customer package still awaits all infrastructure digests and final release evidence.
- Kubernetes remains a reference implementation and is not a self-service `GO` path.
