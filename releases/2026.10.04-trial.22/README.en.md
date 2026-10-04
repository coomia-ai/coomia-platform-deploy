# 2026.10.04-trial.22 shared trial image catalog

English | [简体中文](README.md)

This directory is the authoritative image catalog for the shared trial deployment. The four first-party images
passed protected builds, two-stage security gates, SBOM generation, GHCR Public publication, and anonymous
RepoDigest reads. Infrastructure digests are retained from the validated `trial.7` catalog.

Compose configuration initialization and the Kubernetes reference installer load these defaults. Standard trial
users do not copy image digests from the website. Environment variables override the defaults only when the
publisher explicitly delivers customer-specific images.

This catalog pins images and artifact hashes without changing the root `RELEASE_STATUS=PREPARED`. The release is
not approved for delivery until the complete Kubernetes self-service installer, full-product regression, and human
approval are complete.
