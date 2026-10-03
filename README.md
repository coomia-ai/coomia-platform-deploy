# Coomia AI Data Platform 私有部署

[English](README.en.md) | 简体中文

本仓库用于在客户自有 Linux 环境中部署和运维 Coomia AI Data Platform。交付包只包含部署清单、配置模板和运维脚本，不包含应用源码、Dockerfile、镜像构建上下文、License 私钥或客户凭据。

## 当前发布状态

当前状态为 `PREPARED`。`trial.14` API 热修候选及沿用的 trial.11 UI/Flink RepoDigest 记录在
[`releases/2026.10.03-trial.14/`](releases/2026.10.03-trial.14/)。厂商隔离 K8s 环境已通过 UI 代理、API
健康、License 激活、Flink 运行/checkpoint/savepoint，以及 Doris、对象存储和 TuGraph 项目凭据自动
创建、失败恢复、轮换、跨项目隔离、旧代次吊销和删除清理验收。Kubernetes 因完整核心业务、备份恢复和
客户基础设施产品化尚未完成而继续保持 `REFERENCE_ONLY`。Docker Compose 验证已暂停，`trial.6` 已作废。

| 部署方式 | 定位 | 状态 |
|---|---|---|
| Docker Compose | 单机生产、PoC 和中小规模私有部署 | 验证暂停；不得交付 |
| Kubernetes | 已有集群中的 API 与 Flink 隔离参考 | 项目凭据生命周期通过；核心业务与交付产品化待完成 |

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
