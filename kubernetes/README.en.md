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
- `20-classic-enterprise-api.yaml`, `21-classic-enterprise-flink-namespace.yaml`, `22-classic-enterprise-ui.yaml`, and `render-enterprise.sh`: an isolated Enterprise deployment reference. The renderer only creates and validates a manifest; it never runs `kubectl apply`. It emits dedicated API/UI/Flink namespaces, selectors, the License PVC, and release identity. An external root route is enabled only when an immutable UI image is supplied.
- `snapshot-enterprise.sh`, `verify-enterprise-isolation.sh`, `rollback-enterprise.sh`, and `rollback-enterprise-ui.sh`: a metadata-only snapshot helper, a read-only live isolation/identity/readiness verifier, and rollback helpers with explicit confirmation and complete API/UI release-identity checks; none deploys automatically.
- `enterprise-operations.md`: Enterprise candidate preflight, snapshot, rollout, and rollback steps.

The Enterprise manifest requires `CLASSIC_ENTERPRISE_API_IMAGE` and an independent
`CLASSIC_ENTERPRISE_UI_IMAGE` to be immutable RepoDigests; the Enterprise UI must not reuse
`PLATFORM_UI_IMAGE`. It also requires
`CLASSIC_ENTERPRISE_CORE_REVISION`, `CLASSIC_ENTERPRISE_ENTERPRISE_REVISION`,
`CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION`, and `CLASSIC_ENTERPRISE_RELEASE_INPUTS`. The renderer
writes these identities into Namespace, Deployment, and Pod labels; the full 64-character input digest is kept in annotations while labels use its 63-character prefix. The target namespace must provide
`classic-enterprise-api-secret`, `classic-enterprise-schema-baseline`, and a dedicated database
connection. The Secret and schema baseline must carry `coomia.com/data-scope=enterprise`; the
Secret must contain the required non-empty database, object-storage, graph, cache, JWT, and
delivery-HMAC keys. The read-only verifier checks only metadata and key presence and never prints
Secret values. It does not reuse the `mds-app/platform-api` Service, selectors, License PVC, or configuration.
The rendered candidate creates both namespaces. The Flink namespace only declares the Enterprise boundary;
runtime RBAC and Operator policy must still be pre-provisioned under the target cluster's security baseline.
Both namespaces reject `mds-app`, `mds-flink`, `data-infra`, and the historical
acceptance namespace `mds-m2-acceptance`, so rendering cannot target the shared M2 environment.

The external Ingress is omitted by default. After the authorized host, TLS Secret,
network-policy, and business checks, provide `CLASSIC_ENTERPRISE_INGRESS_HOST`,
`CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET`, and the Ingress controller's
`CLASSIC_ENTERPRISE_INGRESS_NAMESPACE` together to render an isolated
`classic-enterprise-api` Ingress with both `/api/copilotkit` and `/` routes. Rendering
does not change DNS, Secrets, or the cluster; a missing controller namespace fails closed,
and the NetworkPolicy allows controller traffic only from that namespace.

Rendering is not deployment, migration, rollback, or domain acceptance; those require separate evidence
from an authorized environment.

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
