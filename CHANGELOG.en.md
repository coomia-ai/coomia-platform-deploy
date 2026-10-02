# Changelog

English | [简体中文](CHANGELOG.md)

## 0.2.3-prepared - 2026-09-30

- Published the protected API image with the multi-worker first-boot fingerprint race fix and synchronized immutable UI, Flink Local, and Flink K8s digests.
- Passed pre-push and post-push security gates, generated SBOMs, and verified credential-free anonymous reads for all four GHCR packages.
- Updated PostgreSQL 16.14 and TuGraph 4.5.1 digests and recorded vendor-isolated Kubernetes full-stack acceptance.
- Passed the one-day License expiry, final-savepoint, and automatic Flink pause acceptance in the vendor-isolated
  environment on 2026-10-02. The package remains `PREPARED` pending clean-host Linux Compose installation and
  business smoke acceptance.

## 0.2.2-prepared - 2026-09-30

- Replaced the Compose MinIO image, which failed the Critical-vulnerability gate, with the immutable RustFS 1.0.0 RepoDigest.
- Removed the separate `mc` image and reused the protected platform-api image to create private buckets idempotently through the standard S3 API.
- Added the complete infrastructure image catalog and synchronized installer validation, schema, bilingual documentation, and release manifests.

## 0.2.1-prepared - 2026-09-30

- Recorded the four immutable GHCR RepoDigests for the `trial.6` first-party application images.
- Kept generic templates blank and documented the remaining infrastructure, Public-visibility, and final-approval gates.

## 0.2.0-prepared - 2026-09-29

- Restructured the package as an independent customer deployment repository with application image locations left empty.
- Added configuration initialization with strong random credentials and a unified operations command.
- Enforced immutable RepoDigest references and removed default host publication of infrastructure ports.
- Removed demo data, Kafka topic cleanup, public object-store buckets, and default business passwords.
- Corrected clean-volume PostgreSQL initialization and hardened Doris, Flink, and offline License configuration.
- Added bilingual installation, configuration, License, operations, upgrade, backup, security, troubleshooting, and release-admission documentation.
- Added static customer-package security checks and release-state gates.
- Added `AGENTS.md`, `llms.txt`, bilingual AI operations guidance, a machine-readable configuration schema, and a redacted diagnostic collector.

The package is `PREPARED`; this does not mean production release approval has been granted.

## 0.1.0-preview - 2026-09-28

- Created the initial customer deployment directory and Compose/Kubernetes drafts.
