# Upgrade, Backup, and Rollback

English | [简体中文](upgrade-and-backup.md)

An upgrade is a production change. Rehearse it in an isolated environment and obtain customer approval for the maintenance window and rollback criteria.

## Backup scope

Back up at least:

- PostgreSQL databases and role information required for recovery.
- Persistent data in the RustFS object and log volumes, Doris, TuGraph, Kafka, and Redis.
- The `license-state` volume.
- `compose/.env`, generated configuration directories, and the current release package.
- `VERSION`, image RepoDigests, backup time, and checksums.

Copying live container data directories is not a consistent backup. Use component-supported backup methods and validate restoration.

## Upgrade procedure

1. Review release notes and known issues and confirm the supported upgrade path.
2. Rehearse upgrade and rollback in an isolated environment.
3. Stop business writes, record Flink job state, and complete a consistent backup.
4. Preserve the current `compose/.env` and image digests.
5. Replace the deployment package and use its `CURRENT_RELEASE` defaults. Override them only for explicitly issued
   customer-specific images.
6. Run `bash install.sh compose`.
7. Complete health and business acceptance checks before restoring traffic.

Do not use `latest`, temporary tags, or images absent from the release manifest.

Migration from an earlier MinIO release to RustFS is not an in-place upgrade. Complete a consistent backup, copy objects in an isolated environment, validate buckets, object counts, checksums, and access policies, and then schedule a dedicated migration window.

## Rollback

If no irreversible database or data-format change occurred, restore the previous deployment package and image digests. If migrations occurred, restore backups according to that release's notes. Application, database, object data, and License state must return to one consistent recovery point.

## Recovery rehearsal

For each production release, perform at least one clean-environment recovery rehearsal. Record recovery point objective, recovery time objective, validation results, and owner. A backup that has not been restored successfully is not considered recoverable.
