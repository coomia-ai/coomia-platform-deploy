# Changelog

English | [简体中文](CHANGELOG.md)

## 0.2.0-prepared - 2026-09-29

- Restructured the package as an independent customer deployment repository with application image locations left empty.
- Added configuration initialization with strong random credentials and a unified operations command.
- Enforced immutable RepoDigest references and removed default host publication of infrastructure ports.
- Removed demo data, Kafka topic cleanup, public object-store buckets, and default business passwords.
- Corrected clean-volume PostgreSQL initialization and hardened Doris, Flink, and offline License configuration.
- Added bilingual installation, configuration, License, operations, upgrade, backup, security, troubleshooting, and release-admission documentation.
- Added static customer-package security checks and release-state gates.
- Added `AGENTS.md`, `llms.txt`, bilingual AI operations guidance, a machine-readable configuration schema, and a redacted diagnostic collector.

The package is `PREPARED`; this does not mean formal images have been inserted or production release approval has been granted.

## 0.1.0-preview - 2026-09-28

- Created the initial customer deployment directory and Compose/Kubernetes drafts.
