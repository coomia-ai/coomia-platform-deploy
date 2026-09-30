# 2026.09.30-trial.6 Application Images

English | [简体中文](README.md)

This directory records the immutable first-party application image RepoDigests for the shared public trial release.
All four images completed Linux/amd64 builds, protection checks, Critical/secret gates before push and after
RepoDigest pullback, and CycloneDX SBOM generation.

First-party values are in [`application-images.env`](application-images.env), and the Compose infrastructure
RepoDigests are in [`infrastructure-images.env`](infrastructure-images.env). Both files are release inputs; only a
customer package generated, verified, and finally approved by the release workflow may be installed.

Current boundary:

- All four GHCR images are Public and have passed credential-free anonymous reads by RepoDigest.
- The repository remains `PREPARED`; formal installation is not allowed.
- The Compose infrastructure images are digest-pinned. RustFS 1.0.0 passed Critical/secret, SBOM, S3 API, and health-endpoint validation.
- The Docker Compose customer package still awaits complete candidate validation and final release evidence.
- Kubernetes remains a reference implementation and is not a self-service `GO` path.
