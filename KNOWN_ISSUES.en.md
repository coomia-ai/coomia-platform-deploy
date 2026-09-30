# Known Limitations

English | [简体中文](KNOWN_ISSUES.md)

## Current release-preparation items

- The four `trial.6` application images have passed GHCR Public visibility and anonymous RepoDigest pull verification,
  but the complete infrastructure image set is not yet fully approved. This repository remains `PREPARED` until
  release acceptance is complete.
- Kubernetes content is an API and Flink isolation reference only. It does not include the complete UI, Ingress/TLS, monitoring, backup, or all infrastructure components and is not the standard self-service delivery path.

## Productized boundary

- Docker Compose targets a single host and does not provide component-level high availability. Customers requiring high availability, multi-host scheduling, or disaster-recovery failover need a separately designed Kubernetes solution.
- TLS, DNS, external identity, centralized logging, monitoring, alerting, and backup storage are supplied by customer infrastructure.
- On a new installation, the API must be restarted once after registering the first account to complete administrator bootstrap.

These limitations do not permit bypassing the [release admission criteria](docs/release-readiness.en.md). New issues in a formal release must record impact, mitigation, remediation plan, and customer approval.
