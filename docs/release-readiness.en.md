# Release Integrity and Admission

English | [简体中文](release-readiness.md)

`RELEASE_STATUS` is the package release gate. `PREPARED` means the layout, documentation, and candidate images may be ready, but one or more final acceptance records are still missing. Only the publisher may change it to `GO` after review.

## Release admission criteria

- Every image field contains an approved immutable RepoDigest.
- Product images pass source-residue, malware, and vulnerability scans.
- SBOMs, image signatures, and package checksums are generated and verified.
- Clean-environment installation, first-administrator bootstrap, License activation, and basic business acceptance pass.
- Upgrade, rollback, backup, and recovery rehearsals pass.
- Known issues are assessed and release approval is recorded.
- `bash scripts/verify-package.sh` succeeds.

Acceptance evidence must explicitly cover clean-volume PostgreSQL initialization, first-user bootstrap, every infrastructure image, database migration compatibility, platform-ui availability, and the Ingress/TLS responsibility boundary.

## Current state

This directory is currently `PREPARED`. The `trial.11` candidate digests are recorded under
`releases/2026.10.01-trial.11/`. Anonymous reads, isolated Kubernetes API/UI, Doris login, and equality of the Flink
runtime JARs have evidence. A new Flink job, core-business regression, and formal security/SBOM evidence retention are
still pending. Docker Compose validation is paused. Kubernetes remains a reference implementation, and the package
must not be represented as an approved production release or offered for self-service installation.

## Evidence retention

The publisher should create a release-specific manifest from the [release manifest template](../release-manifest.example.en.md) and archive it with `VERSION`, `CHANGELOG`, `KNOWN_ISSUES`, `SHA256SUMS`, signatures, and test reports. The customer should preserve the original materials received.

## Status changes

Before changing status to `GO`, the release owner must verify traceable evidence for every admission criterion. Any image, script, or manifest change invalidates affected evidence and requires revalidation.
