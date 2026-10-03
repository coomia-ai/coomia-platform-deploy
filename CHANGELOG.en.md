# Changelog

English | [简体中文](CHANGELOG.md)

## 0.2.6-prepared - 2026-10-03

- Pinned the protected `trial.14` API RepoDigest while retaining the accepted trial.11 UI and Flink digests.
- Recorded the API two-stage security gates, anonymous pull, two SBOMs, and isolated Kubernetes project-credential
  lifecycle acceptance.
- Updated bilingual release status and image catalogs; Compose, core-business, backup/recovery, and human approval
  remain incomplete.

## 0.2.5-prepared - 2026-10-03

- Wired the Compose and Kubernetes manifests to the automatic project-credential lifecycle: provisioning creates and verifies least-privilege Doris, object-store, and TuGraph identities; rotation reconciles Flink before revoking the old generation; deletion removes every retained managed generation.
- Made the project-credential persistence directory API-exclusive. Kubernetes code accesses deterministic Secret names, and RBAC adds the `update` verb required for rotation while continuing to forbid `list`, `watch`, and `patch`.
- Source and static distribution gates are complete, but the current `trial.11` images do not contain this implementation. A new immutable image and isolated Kubernetes runtime acceptance are required before release, so the package remains `PREPARED` / `REFERENCE_ONLY`.

## 0.2.4-prepared - 2026-10-02

- Added immutable GHCR digests and artifact hashes for the four `trial.11` first-party application images.
- Validated the API/UI, UI proxy, Doris login, and Flink Local/Kubernetes JAR equality in the vendor-isolated Kubernetes environment.
- Compose validation is paused, and a new Flink job plus core-business regression are still pending, so the package remains `PREPARED` / `REFERENCE_ONLY`.

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
