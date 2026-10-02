# 2026.10.01-trial.11 Kubernetes Acceptance Candidate

English | [简体中文](README.md)

This directory records the immutable `trial.11` image RepoDigests. All four GHCR images passed credential-free
anonymous reads by RepoDigest and target `linux/amd64`. The vendor-isolated Kubernetes environment runs the API and UI
digests in this directory; UI proxying, API health, and Doris authentication passed.

The Unified Intake JAR in both Flink Local and Flink Kubernetes images is
`d04fe2680409abdf38891817c7444e0fb68281b6862afc205170713663cb3125`; the SQL Runner JAR in both images is
`8694f78b9d10b71c7b83e550c132572e1fe140a29520c8c035a207efdc74c491`.

Current boundary: a new `trial.11` Flink job, core-business regression, and formal security-scan/SBOM evidence retention
remain pending. Compose validation is paused. Repository and Kubernetes status remain `PREPARED` / `REFERENCE_ONLY`;
this directory does not grant delivery `GO`.
