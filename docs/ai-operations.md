# AI 辅助运维指南

[English](ai-operations.en.md) | 简体中文

本指南用于让 Codex、Claude Code、OpenCode 等 AI 在客户环境中安全地协助安装、检查和排障。AI 必须先遵守仓库根目录的 [`AGENTS.md`](../AGENTS.md)。

## 使用原则

- 将 AI 视为受控运维助手，而不是自动拥有生产变更权限的管理员。
- 默认只允许读取状态、执行健康检查和生成脱敏诊断报告。
- 每次写操作都应限定目标、命令和有效期，不授予笼统的“全权处理”。
- 不要把密码、License、私钥、Token 或完整 `.env` 粘贴到对话中。
- AI 的判断不能替代客户变更审批、备份和恢复验证。

## 推荐起始提示词

```text
请先阅读 AGENTS.md、RELEASE_STATUS、VERSION 和中文文档。
当前环境可能是生产环境。先执行只读检查，不得重启服务、修改配置、
删除容器或数据卷，也不得输出任何密码、Token、License 或连接字符串。
请说明当前状态、发现的问题、建议操作、影响范围和回滚方式。
任何写操作都必须等待我的明确批准。
```

## 安装任务提示词

```text
请按 AGENTS.md 和 docs/getting-started.md 检查这台 Linux 主机是否满足安装条件。
先确认 RELEASE_STATUS 和 COMPOSE_STATUS 均为 GO，并验证镜像均为不可变 RepoDigest。
只完成预检和配置缺失项清单，不要启动安装。输出预计影响、端口、数据目录、
License 模式和验收步骤，等待我批准后再执行 bash install.sh compose。
```

AI 不得自行填写镜像地址、猜测客户域名或生成正式 License。

## 健康检查提示词

```text
请执行只读健康检查，并运行 bash scripts/collect-diagnostics.sh。
不要收集应用日志、容器环境变量或 compose/.env 内容。
按服务列出健康状态、异常、证据、可能原因和下一步建议。
不要重启任何服务。
```

## 故障排查提示词

```text
请按照 docs/troubleshooting.md 排查该问题。
先记录故障时间、影响范围、版本和最近变更，再做只读检查。
不要假设 503 等于 License 到期，不要删除或重建任何数据服务。
如建议重启或改配置，先给出影响范围、风险和回滚方法，等待批准。
```

## 升级提示词

```text
请按照 docs/upgrade-and-backup.md 评估升级，不要执行升级。
核对发布状态、版本路径、镜像摘要、已知问题、备份恢复证据、维护窗口和回滚条件。
输出升级计划和阻塞项。没有经过验证的备份时必须停止。
```

## License 提示词

```text
请按照 docs/license.md 只读检查 License 模式、API 健康和系统时间。
不要显示或复制 License 文件，不要修改 JWT，不要关闭授权校验。
请区分 License 问题、API 不可用和上游基础设施故障。
```

## 诊断报告

运行：

```bash
bash scripts/collect-diagnostics.sh
```

报告默认写入 `diagnostics/`，权限为 `0600`。报告不采集 `.env` 内容、License、容器环境变量或应用日志。它仍可能包含主机名、端口、容器状态和基础设施信息，发送给外部人员前必须由客户审阅。

## AI 输出格式

要求 AI 最终给出：

1. 环境与版本。
2. 已执行的只读检查。
3. 已获批准并执行的写操作。
4. 健康检查和业务验收结果。
5. 未完成、失败或跳过的检查。
6. 风险、回滚点和诊断报告路径。

AI 不得把“命令执行成功”等同于“业务验收通过”。
