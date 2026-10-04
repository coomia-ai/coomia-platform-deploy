# Kubernetes Deployment Reference

English | [简体中文](README.md)

This directory provides a security reference for platform-api and Flink workload isolation. It is not a complete one-command Kubernetes product installer. It assumes an existing production Kubernetes platform with persistent storage, Ingress/TLS, the Flink Kubernetes Operator, PostgreSQL, MinIO, Doris, Kafka, Redis, Nessie, and TuGraph.

Its current status is `REFERENCE_ONLY`. Do not apply it directly to a customer production cluster without a joint review with the publisher. The installer runs only after `KUBERNETES_STATUS` is changed to `GO`.

The generated package's `release-manifest.md` and matching `releases/<version>/` directory are authoritative for current
candidate digests. `trial.22` passed isolated Kubernetes acceptance for License, project-credential lifecycle, Flink
savepoint upgrades, the object/checkpoint/Iceberg/Action core workflow, and application-level recovery of PostgreSQL,
Nessie, object storage, Doris, TuGraph, Kafka, Redis, and License state. A complete self-service installer,
full-product regression, and human approval remain incomplete, so this reference must not be changed to `GO`.

Included material:

- `10-platform-api.yaml`: API, License PVC, ServiceAccount, and Flink control-plane RBAC;
- `mds-flink-namespace.yaml`: Flink namespace, least-privilege runtime access, and admission isolation policies;
- `apply-flink-isolation.sh`: applies and actively verifies the admission boundary;
- `install.sh`: validates image digests, Secrets, and manifests before deployment.

The reference installer automatically loads these shared release variables from
[`CURRENT_RELEASE`](../CURRENT_RELEASE), with every image supplied as an immutable RepoDigest:

- `PLATFORM_API_IMAGE`
- `FLINK_K8S_IMAGE`
- `K8S_PROBE_IMAGE`
- `FLINK_UNIFIED_ARTIFACT_SHA256`

Public trial images use `ghcr.io/coomia-ai/...@sha256:...` and require no image-pull Secret.
Standard trial users do not copy digests from the website. Override the defaults through environment variables only
when the publisher explicitly issues customer-specific images.
Set `PLATFORM_API_IMAGE_PULL_SECRET` and `FLINK_K8S_IMAGE_PULL_SECRET` only for a private Registry;
the installer then verifies the Secrets in `mds-app` and `mds-flink` respectively.

Production implementation requires a joint capacity, storage class, network policy, backup, upgrade, and disaster recovery review by the customer platform team and the publisher.
