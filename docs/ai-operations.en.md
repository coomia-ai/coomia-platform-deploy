# AI-Assisted Operations Guide

English | [简体中文](ai-operations.md)

This guide helps Codex, Claude Code, OpenCode, and similar agents assist with installation, inspection, and troubleshooting in customer environments. The agent must first follow [`AGENTS.md`](../AGENTS.md) at the repository root.

## Operating principles

- Treat the AI as a controlled operations assistant, not an administrator with implicit production authority.
- Permit read-only discovery, health checks, and redacted diagnostic collection by default.
- Scope every write approval to a specific target, command, and time. Do not grant blanket authorization.
- Never paste passwords, Licenses, private keys, tokens, or the complete `.env` into a conversation.
- AI judgment does not replace customer change approval, backup, or recovery validation.

## Recommended initial prompt

```text
Read AGENTS.md, RELEASE_STATUS, VERSION, and the English documentation first.
This may be a production environment. Begin with read-only checks. Do not restart services,
change configuration, remove containers or volumes, or display passwords, tokens, Licenses,
or connection strings. Report the current state, findings, proposed action, impact, and rollback.
Wait for my explicit approval before every write operation.
```

## Installation prompt

```text
Follow AGENTS.md and docs/getting-started.en.md to assess this Linux host.
First confirm RELEASE_STATUS and COMPOSE_STATUS are GO and every image is an immutable RepoDigest.
Perform preflight and produce a missing-configuration list only. Do not install yet.
Report expected impact, ports, data directories, License mode, and acceptance steps.
Wait for approval before running bash install.sh compose.
```

The AI must not invent image locations, guess customer hostnames, or generate a formal License.

## Health-check prompt

```text
Perform read-only health checks and run bash scripts/collect-diagnostics.sh.
Do not collect application logs, container environment variables, or compose/.env content.
List service health, anomalies, evidence, likely causes, and recommended next steps.
Do not restart any service.
```

## Troubleshooting prompt

```text
Follow docs/troubleshooting.en.md. Record incident time, impact, version, and recent changes,
then perform read-only checks. Do not assume HTTP 503 means License expiry and do not delete
or recreate data services. Before suggesting a restart or configuration change, provide impact,
risk, and rollback and wait for approval.
```

## Upgrade prompt

```text
Assess the upgrade using docs/upgrade-and-backup.en.md, but do not execute it.
Verify release state, upgrade path, image digests, known issues, backup and recovery evidence,
maintenance window, and rollback criteria. Produce the plan and blockers. Stop when no verified
backup exists.
```

## License prompt

```text
Use docs/license.en.md to inspect License mode, API health, and system time without making changes.
Do not display or copy the License file, modify its JWT, or disable enforcement.
Distinguish License failure from API unavailability and upstream infrastructure failure.
```

## Diagnostic report

Run:

```bash
bash scripts/collect-diagnostics.sh
```

The report is written to `diagnostics/` with mode `0600`. It excludes `.env` content, Licenses, container environment variables, and application logs. It may still contain hostnames, ports, container state, and infrastructure metadata, so the customer must review it before external transfer.

## Required AI completion report

The final response must include:

1. Environment and version.
2. Read-only checks performed.
3. Approved write operations performed.
4. Health and business acceptance results.
5. Incomplete, failed, or skipped checks.
6. Risks, rollback point, and diagnostic report path.

A successful command is not equivalent to successful business acceptance.
