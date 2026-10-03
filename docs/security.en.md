# Security

English | [简体中文](security.md)

## Security boundary

This package does not contain application source, Dockerfiles, License private keys, or customer credentials. The publisher should release product images by immutable RepoDigest and record SBOM, signature verification, and source-residue scan evidence in the release manifest.

Code protection raises reverse-engineering cost but does not replace access control, License enforcement, image signing, vulnerability management, or contractual software terms.

## Credentials and keys

- `compose/.env` must use mode `0600`, and backups must be encrypted.
- Project credentials are generated and stored atomically by the API; `MDS_INTAKE_SECRETS_DIR` must be an API-exclusive persistent directory with mode `0700` and record mode `0600`.
- Do not reuse JWT, HMAC, database, Redis, object-store, or Flink control secrets.
- Keep the License private key only in the publisher's issuing environment.
- After secret exposure, revoke or rotate it immediately and assess issued tokens and backups.

## Network

Infrastructure services join internal networks and do not publish host ports by default. Place UI and API behind the customer's reverse proxy for TLS, access control, rate limiting, and audit. Optional administration ports must bind to `127.0.0.1` only.

## Containers and host

Keep Docker, the Linux kernel, and third-party images on supported versions. Limit Docker group membership because Docker access is effectively privileged host access. The Flink gateway mounts the Docker socket read-only but remains security-sensitive; restrict its network and token use.

## Data protection

RustFS buckets are created without anonymous policies. Apply customer data-classification, encryption, retention, and destruction policies to backups, logs, and exports. Troubleshooting must never upload production data to an unapproved system.

## Vulnerability response

For a suspected security issue, preserve the version, image digests, timeline, and minimum required logs; stop actions that expand impact; and contact the publisher through the contracted security channel. Do not disclose exploit details or credentials in public channels.
