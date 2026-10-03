# Coomia AI Data Platform Private Deployment

English | [简体中文](README.md)

This repository installs and operates Coomia AI Data Platform in a customer-managed Linux environment. It contains deployment manifests, configuration templates, and operational scripts only. It does not contain application source code, Dockerfiles, image build contexts, license private keys, or customer credentials.

## Release status

The package is currently `PREPARED`. Anonymous reads verified the four public `trial.11` first-party RepoDigests,
recorded under [`releases/2026.10.01-trial.11/`](releases/2026.10.01-trial.11/). The vendor-isolated Kubernetes
environment runs the `trial.11` API and UI; UI proxying, API health, and Doris authentication passed. A newly issued
License activated successfully and synchronized across API workers. A fresh Flink job using the immutable `trial.11`
RepoDigest reached `RUNNING/READY/STABLE`, advanced checkpoints, and suspended with a final savepoint. Automatic
creation, recoverable rotation, deletion cleanup, and bound Secret persistence for project-scoped Doris,
object-storage, and TuGraph credentials are now implemented in source and deployment manifests. A new candidate image
has not yet completed isolated Kubernetes runtime acceptance, so Kubernetes remains `REFERENCE_ONLY`. Docker Compose
validation is paused, and the existing `trial.7` candidate has not
received delivery `GO`. The incompatible `trial.6` candidate remains invalid.

| Deployment path | Intended use | Status |
|---|---|---|
| Docker Compose | Single-node production, PoC, and small-to-medium private deployments | Validation paused; not deliverable |
| Kubernetes | API and Flink isolation reference for an existing cluster | Automation implemented; new image and runtime acceptance pending |

## Quick start

Run the following on a clean Linux amd64 host:

```bash
bash scripts/init-config.sh
vi compose/.env
bash install.sh compose
```

Fill every image field in `compose/.env` with the RepoDigest supplied by the publisher:

```text
<registry>/<image>@sha256:<64-hex-digest>
```

After installation:

1. Open `http://<server-address>:3000` and register the first account.
2. Run `bash compose/manage.sh restart-api` once.
3. Sign in with the first account. When no administrator exists, the earliest registered account is promoted to platform administrator during API startup.
4. Import or activate the License from the license administration page.
5. Run `bash compose/manage.sh health` to verify the UI and API.

## Documentation

- [Installation guide](docs/getting-started.en.md)
- [Deployment architecture](docs/architecture.en.md)
- [AI-assisted operations](docs/ai-operations.en.md)
- [Configuration reference](docs/configuration.en.md)
- [License operations](docs/license.en.md)
- [Routine operations](docs/operations.en.md)
- [Upgrade, backup, and rollback](docs/upgrade-and-backup.en.md)
- [Troubleshooting](docs/troubleshooting.en.md)
- [Security](docs/security.en.md)
- [Release integrity](docs/release-readiness.en.md)

## Common commands

```bash
bash compose/manage.sh status
bash compose/manage.sh logs platform-api
bash compose/manage.sh restart-api
bash compose/manage.sh health
bash scripts/collect-diagnostics.sh
bash compose/manage.sh stop
bash compose/manage.sh start
```

`stop` and `down` preserve data volumes. Any volume deletion must be handled separately after a verified backup and explicit customer approval.

When using an AI agent with this repository, instruct it to read [`AGENTS.md`](AGENTS.md) first. `llms.txt` provides a compact machine-oriented documentation index.

## Support boundary

Keep a protected copy of `VERSION`, `RELEASE_STATUS`, all image RepoDigests, `compose/.env`, and the License state volume. Changes to Compose networking, container privileges, license enforcement, or the Flink Docker gateway security policy move the deployment outside this release's standard support boundary.

The deployment materials and product images are governed by the [Coomia Proprietary Software License](LICENSE). Third-party components remain subject to their respective licenses.
