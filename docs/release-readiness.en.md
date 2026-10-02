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

This directory is currently `PREPARED`. Image fields in the generic `compose/.env.example` intentionally remain empty;
the approved `trial.7` candidate digests are recorded under `releases/2026.09.30-trial.7/` and are entered into the
customer's private `compose/.env` after initialization. Image security gates, anonymous pulls, the vendor-isolated
Kubernetes full stack, one-day License expiry, and automatic Flink pause after a final savepoint have evidence.
Clean-host Linux Compose installation and business smoke acceptance are still outstanding. Kubernetes remains a
reference implementation. The package must not be represented as an approved production release or offered for
self-service installation in its current state.

## Evidence retention

The publisher should create a release-specific manifest from the [release manifest template](../release-manifest.example.en.md) and archive it with `VERSION`, `CHANGELOG`, `KNOWN_ISSUES`, `SHA256SUMS`, signatures, and test reports. The customer should preserve the original materials received.

## Status changes

Before changing status to `GO`, the release owner must verify traceable evidence for every admission criterion. Any image, script, or manifest change invalidates affected evidence and requires revalidation.
