# Troubleshooting

English | [简体中文](troubleshooting.md)

Before troubleshooting, record the incident time, version, recent changes, and impact. Do not experiment by deleting volumes, recreating databases, or disabling security controls.

## Installer rejects an image

Confirm the value is non-empty and uses `registry/image@sha256:<64-lowercase-hex-digest>`. Tags are not accepted.

## UI returns 502 or 503

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
bash compose/manage.sh logs platform-ui
```

HTTP 503 first means the application or an upstream service is unavailable; it is not sufficient evidence of License expiry. Check API health, container restarts, database connectivity, disk capacity, and reverse-proxy configuration.

## Cannot sign in after registration

On a new installation, register the first account and then run:

```bash
bash compose/manage.sh restart-api
```

Sign in with the earliest registered account. If an administrator already exists, the system does not promote another account automatically.

## License import fails

Confirm the file came from the approved issuing process for this environment, has not been modified, and is not bound to another instance. In offline mode, also check the public-key path, mount permissions, and system time. Preserve the API error code but do not transmit the full License.

## Flink job failure

Check API and Flink gateway logs, Docker socket permissions, the control token, artifact-directory ownership, and disk capacity. Do not manually delete Flink job containers. Stop or cancel the job through the platform and confirm state convergence.

## Infrastructure failure

Use `status` to identify the unhealthy service and inspect only that service's logs. For full disks, database corruption, or repeated restarts, stop writes and enter the recovery procedure. Do not remove files directly from volumes.
