# Routine Operations

English | [简体中文](operations.md)

## Status and health

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
```

Customer monitoring should continuously check UI and API health, container state, disk usage, certificate expiry, License expiry, and Flink job state. Forward logs to the customer logging platform with a retention period appropriate for compliance requirements.

Generate a redacted diagnostic report with:

```bash
bash scripts/collect-diagnostics.sh
```

The report is stored under `diagnostics/` and excludes `.env` content, Licenses, container environment variables, and application logs. The customer must still review it before external transfer.

## Start and stop

```bash
bash compose/manage.sh stop
bash compose/manage.sh start
bash compose/manage.sh restart-api
```

Both `stop` and `down` preserve data volumes. Never use a removal command with `--volumes`. Before planned downtime, stop business writes, confirm Flink job state, and complete a backup.

## Logs

```bash
bash compose/manage.sh logs
bash compose/manage.sh logs platform-api
bash compose/manage.sh logs platform-ui
```

Support requests should include the incident interval, version, relevant service logs, and reproduction steps. Redact access tokens, passwords, full License content, and business-sensitive data before transfer.

## Capacity management

Monitor the Docker data root, PostgreSQL, MinIO, Doris, Kafka, and the Flink artifact directory. When disk use reaches the customer alert threshold, identify the source before an approved archive or expansion. Do not delete files directly from container volumes.

## Change management

Record every image, configuration, certificate, network, and secret change with a change ticket, rollback criteria, and validation results. Do not modify configuration inside a running container because container recreation discards such changes.
