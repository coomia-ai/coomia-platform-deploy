# 2026.10.03-trial.14 Kubernetes Project-Credential Acceptance Candidate

English | [简体中文](README.md)

This directory records the immutable public-trial `trial.14` image digests. The API is a new protected image built from
source commit `13de75d82a9ca1ccad1376d9661c2b4d1ea7c34a`. UI, Flink Local, and Flink Kubernetes retain the digests
accepted in `trial.11`, so this is an API hotfix candidate rather than a four-image rebuild.

The `trial.14` API passed the protected build, pre-push and RepoDigest Critical/Secret gates, anonymous pull, and two
SBOM checks. In the vendor-isolated Kubernetes environment, the API and Flink Kubernetes digests in this catalog passed
automatic project-credential creation, failed-rotation recovery, rotation, Doris/object-storage/TuGraph cross-project
isolation, old-generation revocation, and deletion cleanup.

Docker Compose was not started and remains paused. Complete core-business, backup/recovery, and customer-environment
installation acceptance also remain incomplete. Repository and Kubernetes status stay `PREPARED` / `REFERENCE_ONLY`;
this directory does not grant delivery `GO`.
