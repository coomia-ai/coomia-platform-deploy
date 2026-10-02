# Known Limitations

English | [简体中文](KNOWN_ISSUES.md)

## Current release-preparation items

- The vendor-isolated Kubernetes environment now runs the `trial.11` API/UI. UI proxying, API health, Doris login,
  and Flink Local/Kubernetes JAR equality passed; a new Flink job and core-business regression remain pending. Docker
  Compose validation is paused, so the repository remains `PREPARED`. The prior `trial.7` one-day License expiry,
  final savepoint, and automatic pause evidence is retained but does not replace `trial.11` runtime acceptance.
- The old `trial.6` candidate contains TuGraph 3.5.0 without the required Bolt interface and must not be delivered.
- RustFS uses the new `coomia-object-storage-data` volume. An existing MinIO volume must not be mounted directly into
  RustFS; migration requires a separately designed, backup-verified object-level migration rather than an in-place upgrade.
- Kubernetes content is an API and Flink isolation reference only. It does not include the complete UI, Ingress/TLS, monitoring, backup, or all infrastructure components and is not the standard self-service delivery path.

## Productized boundary

- Docker Compose targets a single host and does not provide component-level high availability. Customers requiring high availability, multi-host scheduling, or disaster-recovery failover need a separately designed Kubernetes solution.
- TLS, DNS, external identity, centralized logging, monitoring, alerting, and backup storage are supplied by customer infrastructure.
- On a new installation, the API must be restarted once after registering the first account to complete administrator bootstrap.

These limitations do not permit bypassing the [release admission criteria](docs/release-readiness.en.md). New issues in a formal release must record impact, mitigation, remediation plan, and customer approval.
