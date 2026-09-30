# Coomia AI Data Platform 私有部署

[English](README.en.md) | 简体中文

本仓库用于在客户自有 Linux 环境中部署和运维 Coomia AI Data Platform。交付包只包含部署清单、配置模板和运维脚本，不包含应用源码、Dockerfile、镜像构建上下文、License 私钥或客户凭据。

## 当前发布状态

当前状态为 `PREPARED`：Docker Compose 交付结构、安装脚本和客户文档已经准备完成。`trial.7` 的四个
一方镜像已完成加密构建、安全门禁、GHCR Public 与匿名 RepoDigest 读取验证，摘要记录在
[`releases/2026.09.30-trial.7/`](releases/2026.09.30-trial.7/)。厂商隔离 K8s 全栈已验证修正后的
PostgreSQL 16.14 和 TuGraph 4.5.1 摘要，以及 RustFS、Nessie、Doris、Kafka、Redis、API 和 UI。
客户 Compose 仍需完成干净主机安装、1 天 License 生命周期、Flink 到期自动暂停和最终放行，之后才能
将 `RELEASE_STATUS` 切换为 `GO`。`trial.6` 旧候选包含不兼容 TuGraph，已作废且不得交付。

| 部署方式 | 定位 | 状态 |
|---|---|---|
| Docker Compose | 单机生产、PoC 和中小规模私有部署 | 推荐；trial.7 候选等待干净主机验收与最终放行 |
| Kubernetes | 已有集群中的 API 与 Flink 隔离参考 | 需要交付方实施支持 |

## 快速开始

在全新的 Linux amd64 主机上执行：

```bash
bash scripts/init-config.sh
vi compose/.env
bash install.sh compose
```

在 `compose/.env` 中填写交付方提供的全部镜像 RepoDigest。格式必须为：

```text
<镜像仓库>/<镜像名称>@sha256:<64 位十六进制摘要>
```

安装完成后：

1. 打开 `http://<服务器地址>:3000` 并注册第一个账号。
2. 执行 `bash compose/manage.sh restart-api`。
3. 使用第一个账号登录；系统会在没有管理员时将最早注册账号提升为平台管理员。
4. 在授权管理页面导入或激活 License。
5. 执行 `bash compose/manage.sh health` 验证 UI 和 API。

## 文档

- [安装指南](docs/getting-started.md)
- [部署架构](docs/architecture.md)
- [AI 辅助运维](docs/ai-operations.md)
- [配置参考](docs/configuration.md)
- [License 操作](docs/license.md)
- [日常运维](docs/operations.md)
- [升级、备份与回滚](docs/upgrade-and-backup.md)
- [故障排查](docs/troubleshooting.md)
- [安全说明](docs/security.md)
- [发布完整性](docs/release-readiness.md)

## 常用命令

```bash
bash compose/manage.sh status
bash compose/manage.sh logs platform-api
bash compose/manage.sh restart-api
bash compose/manage.sh health
bash scripts/collect-diagnostics.sh
bash compose/manage.sh stop
bash compose/manage.sh start
```

`stop` 和 `down` 默认保留数据卷。任何删除数据卷的操作都必须在完成备份并获得客户明确批准后单独执行。

使用 AI 操作本仓库时，应先让 AI 阅读根目录的 [`AGENTS.md`](AGENTS.md)。`llms.txt` 提供适合模型快速读取的文档索引。

## 支持边界

客户应保存当前版本的 `VERSION`、`RELEASE_STATUS`、镜像 RepoDigest、`compose/.env` 的安全备份以及 License 状态卷备份。修改 Compose 网络、容器权限、授权门禁或 Flink Docker 网关安全策略后，部署将不再属于本版本的标准支持范围。

部署资料和产品镜像受 [Coomia Proprietary Software License](LICENSE) 约束。第三方组件继续适用各自许可证。
