# 2026.10.01-trial.11 Kubernetes Acceptance Candidate

English | [简体中文](README.md)

This directory records the immutable `trial.11` image RepoDigests. All four GHCR images passed credential-free
anonymous reads by RepoDigest and target `linux/amd64`. The vendor-isolated Kubernetes environment runs the API and UI
digests in this directory; UI proxying, API health, and Doris authentication passed.

The Unified Intake JAR in both Flink Local and Flink Kubernetes images is
`d04fe2680409abdf38891817c7444e0fb68281b6862afc205170713663cb3125`; the SQL Runner JAR in both images is
`8694f78b9d10b71c7b83e550c132572e1fe140a29520c8c035a207efdc74c491`.

A fresh `trial.11` Flink job reached `RUNNING/READY/STABLE`; completed checkpoints advanced from 17 to 23 without an
increase in failures, checkpoint metadata and shared objects were present in object storage, and suspension completed
with a final savepoint. Core-business regression is blocked by missing project credential automation. Formal
security-scan/SBOM evidence retention also remains pending, and Compose validation is paused. Repository and Kubernetes
status remain `PREPARED` / `REFERENCE_ONLY`; this directory does not grant delivery `GO`.
