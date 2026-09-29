# Release Manifest Template

English | [简体中文](release-manifest.example.md)

> This is a template. For a formal release, copy it to `release-manifest.md` and have the release owner complete and sign it. All image fields intentionally remain empty in this package.

| Field | Value |
|---|---|
| Version |  |
| Release date |  |
| Release owner |  |
| Release status |  |
| Supported deployment path |  |

## Images

| Component | Immutable RepoDigest | SBOM | Signature evidence |
|---|---|---|---|
| platform-api |  |  |  |
| platform-ui |  |  |  |
| Flink runtime |  |  |  |
| PostgreSQL |  |  |  |
| MinIO / mc |  |  |  |
| Nessie |  |  |  |
| TuGraph |  |  |  |
| Doris FE / BE |  |  |  |
| Kafka |  |  |  |
| Redis |  |  |  |

## Release evidence

| Check | Evidence location | Result |
|---|---|---|
| Product-image source-residue scan |  |  |
| Vulnerability and malware scan |  |  |
| Clean-environment installation |  |  |
| First administrator and License activation |  |  |
| Core business acceptance |  |  |
| Upgrade and rollback |  |  |
| Backup and recovery |  |  |
| Known-issue approval |  |  |

## Package integrity

| Item | Value |
|---|---|
| `SHA256SUMS` |  |
| Package signature |  |
| `bash scripts/verify-package.sh` |  |

Release approver:

Approval time:

Signature or approval record:
