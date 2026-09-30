# 2026.09.30-trial.7 Public Trial Candidate

English | [简体中文](README.md)

This directory records the immutable image RepoDigests for public trial `trial.7`. It adds an API fix for the
concurrent creation of the persistent machine-fingerprint file during multi-worker first boot. All four first-party
images completed Linux/amd64 builds, source-protection checks, Critical/secret gates before push and after RepoDigest
pullback, CycloneDX SBOM generation, and credential-free GHCR reads.

First-party values are in [`application-images.env`](application-images.env), and the Compose infrastructure
RepoDigests are in [`infrastructure-images.env`](infrastructure-images.env). Both files are release inputs; only a
customer package generated, verified, and finally approved by the release workflow may be installed.

Current boundary:

- All four GHCR images are Public and passed credential-free anonymous reads by RepoDigest.
- Vendor-isolated Kubernetes acceptance covered PostgreSQL, RustFS, Nessie, TuGraph 4.5.1, Doris, Kafka, Redis, API, and UI.
- Both API workers use the same stable machine fingerprint, and the license status endpoint is healthy.
- The repository remains `PREPARED`; clean-host Compose installation, the one-day License lifecycle, and automatic Flink pause on expiry remain open.
- Kubernetes remains a reference implementation and is not a self-service `GO` path.
