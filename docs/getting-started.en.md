# Installation Guide

English | [简体中文](getting-started.md)

This guide installs Coomia AI Data Platform on a customer-managed Linux host. Production installation requires approved capacity, security, backup, and change plans.

## 1. Supported scope

- Operating system: mainstream Linux amd64 distribution.
- Runtime: Docker Engine and Docker Compose v2.
- Recommended baseline: at least 8 vCPU, 16 GiB RAM, and 50 GiB free disk. Size production systems separately.
- Network: access to the publisher's image registry and License service, except for offline licensing.
- Permissions: the installation account can use Docker and owns the three customer data directories.

The Kubernetes manifests are a reference implementation and are not an unattended standard installation path. See [Kubernetes deployment](../kubernetes/README.en.md).

## 2. Validate release materials

Before installation, confirm that:

1. `RELEASE_STATUS` is approved by the publisher.
2. `VERSION` matches the release manifest.
3. Every image uses an immutable `@sha256:` RepoDigest; floating tags are not accepted.
4. The package checksum matches the publisher-provided `SHA256SUMS`.
5. The appropriate License file or online entitlement information is available.

Shared image digests are pinned by the release directory selected in
[`CURRENT_RELEASE`](../CURRENT_RELEASE). Standard trial users do not copy or select images from the website. Override
the defaults only when the publisher explicitly delivers customer-specific images. Release gates remain independent,
and a `PREPARED` package cannot install.

## 3. Initialize configuration

```bash
bash scripts/preflight-linux.sh compose
bash scripts/init-config.sh
vi compose/.env
```

`init-config.sh` loads the current release's shared immutable images, generates random credentials, and sets
`compose/.env` to mode `0600`. Review directories, ports, network ranges, and License mode. Override image fields only
for a customer-specific image delivery. See the [configuration reference](configuration.en.md).

## 4. Install

```bash
bash install.sh compose
```

The installer validates configuration, pulls digest-pinned images, attests the Flink runtime, generates the Doris password configuration, renders the Compose model, and waits for service health. A failed step stops the installation with a non-zero exit code.

## 5. Bootstrap the first administrator

1. Open `http://<server-address>:3000` and register the first account.
2. Run `bash compose/manage.sh restart-api`.
3. Sign in with the first account.
4. Import or activate the License from the administration page.

Only when no administrator exists does API startup promote the earliest registered account. Do not perform this workflow while public registration is exposed to the Internet.

## 6. Acceptance checks

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
```

Acceptance must cover sign-in, License state, a data-source connection, a test pipeline submission, Flink job state, object-store writes, and absence of persistent log errors. Archive the results with the version, image digests, and execution time.

## 7. Next steps

- [Routine operations](operations.en.md)
- [Upgrade, backup, and rollback](upgrade-and-backup.en.md)
- [Security](security.en.md)
- [Troubleshooting](troubleshooting.en.md)
