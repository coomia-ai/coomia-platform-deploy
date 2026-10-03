# Configuration Reference

English | [简体中文](configuration.md)

The customer configuration file is `compose/.env`. It contains credentials, must use mode `0600`, and must never be committed to Git or pasted into tickets or chat.

The machine-readable configuration contract is [`schemas/compose-env.schema.json`](../schemas/compose-env.schema.json). The schema describes a parsed customer configuration; blank image placeholders in the distribution template must be replaced with approved RepoDigests before installation.

## Images

The publisher must fill `PLATFORM_API_IMAGE`, `PLATFORM_UI_IMAGE`, `FLINK_LOCAL_IMAGE`, and every infrastructure image variable. Each value must be a complete RepoDigest:

Public trial application images come from `ghcr.io/coomia-ai`, for example:

```text
PLATFORM_API_IMAGE=ghcr.io/coomia-ai/coomia-platform-api@sha256:<published-digest>
PLATFORM_UI_IMAGE=ghcr.io/coomia-ai/coomia-platform-ui@sha256:<published-digest>
FLINK_LOCAL_IMAGE=ghcr.io/coomia-ai/coomia-flink-local@sha256:<published-digest>
```

The four current `trial.11` first-party digests are recorded in
[`releases/2026.10.01-trial.11/application-images.env`](../releases/2026.10.01-trial.11/application-images.env).
The complete infrastructure image catalog is recorded in
[`releases/2026.10.01-trial.11/infrastructure-images.env`](../releases/2026.10.01-trial.11/infrastructure-images.env).
Together, the two files define the candidate image set, which still requires final release approval.

```text
<registry>/<image>@sha256:<64-lowercase-hex-digest>
```

The installer rejects tags, empty values, and non-digest references.

## Database and infrastructure credentials

`POSTGRES_USER` and `POSTGRES_DB` may contain letters, digits, and underscores only. `DATABASE_URL` must match the PostgreSQL settings. `OBJECT_STORAGE_ACCESS_KEY` and `OBJECT_STORAGE_SECRET_KEY` are the S3-compatible credentials used by RustFS; the application still receives mapped `MINIO_*` variables for SDK compatibility. This release requires `DORIS_USER=root` and a Doris password of at least 12 characters. The Kubernetes installer requires `mds-app/platform-api-secret.DORIS_PASSWORD` to exactly match `data-infra/doris-root-secret.password`; the Compose installer performs a real Doris login with the credentials visible inside the API container after startup. `init-config.sh` generates the remaining passwords.

In customer mode, the API uses those platform administration credentials to create a dedicated Doris user, object-store user and bucket policy, and TuGraph user and graph role for every project. Active credentials are stored as an atomic record under `MDS_INTAKE_SECRETS_DIR`; rotation revokes the previous generation only after Flink job reconciliation, and project deletion stops writes before removing every retained managed generation. The directory must be writable only by the API, with mode `0700` and record mode `0600`; do not edit it manually or reuse platform administrator credentials as project credentials.

The UI image always calls the backend through same-origin `/api` and reads `INTERNAL_API_URL` at container runtime. The Compose installer requests `/api/v1/license/status` from inside the UI container and fails installation when the proxy is broken; container Ready state alone is not acceptance evidence.

## Application secrets

- `JWT_SECRET`: signs login tokens.
- `DELIVERY_REPORT_HMAC_SECRET`: signs delivery reports and must differ from the JWT secret.
- `MDS_FLINK_CONTROL_TOKEN`: authenticates API access to the local Flink gateway.

Confirm version compatibility before rotating secrets and perform rotation in a maintenance window. Do not edit the environment of running containers directly.

## License

- `LICENSE_MODE=online`: the API validates entitlement through `LICENSE_SERVER_URL`.
- `LICENSE_MODE=offline`: `COOMIA_LICENSE_PUBLIC_KEY_FILE` is required and must contain only the publisher's public key.

See [License operations](license.en.md).

## Customer data directories

The following values must be absolute, customer-owned, independent directories that do not contain one another:

- `MDS_FLINK_ARTIFACT_DIR`
- `MDS_GENERATED_CONFIG_DIR`
- `MDS_INTAKE_SECRETS_DIR`

The installer rejects root and system directories, symbolic links, and paths that are too broad.

## Network and ports

`BIND_ADDRESS` controls the UI and API listeners. Production deployments should terminate TLS at a reverse proxy or load balancer and restrict administrative API access. PostgreSQL, Kafka, Redis, RustFS, Doris, and TuGraph are not published to the host by default.

Set `CORS_ORIGINS` to the trusted origin used to access the UI, such as the customer's production HTTPS hostname. Follow the release notes for multiple-origin syntax. Do not use a wildcard in production.

If `MDS_DATA_SUBNET` conflicts with the customer network, change the subnet, gateway, and Doris fixed addresses before first installation. Changing this network after go-live is a migration.

## Optional administration ports

Use `compose/docker-compose.admin.yml` only for local troubleshooting. It binds ports to `127.0.0.1` and must not be changed to a public address. Remove the additional manifest after troubleshooting.
