# Coomia AI Data Platform Private Deployment

English | [简体中文](README.md)

This repository installs and operates Coomia AI Data Platform in a customer-managed Linux environment. It contains deployment manifests, configuration templates, and operational scripts only. It does not contain application source code, Dockerfiles, image build contexts, license private keys, or customer credentials.

## Release status

The package is currently `PREPARED`. The Docker Compose layout, installer, and customer documentation are ready.
The `trial.6` first-party images have passed GHCR Public and anonymous RepoDigest-read verification and are recorded under
[`releases/2026.09.30-trial.6/`](releases/2026.09.30-trial.6/). Generic configuration templates intentionally remain
blank. The complete customer package still requires approved infrastructure RepoDigests and final release evidence
before `RELEASE_STATUS` can change to `GO`.

| Deployment path | Intended use | Status |
|---|---|---|
| Docker Compose | Single-node production, PoC, and small-to-medium private deployments | Recommended; application images published, awaiting infrastructure digests and final approval |
| Kubernetes | API and Flink isolation reference for an existing cluster | Requires publisher-assisted implementation |

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
