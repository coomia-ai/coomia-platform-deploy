# 2026.09.30-trial.6 应用镜像

[English](README.en.md) | 简体中文

本目录记录公共试用版本的一方应用镜像 RepoDigest。四个镜像已经完成 Linux/amd64 构建、保护检查、
推送前与 RepoDigest 回拉后的 Critical/secret 门禁，以及 CycloneDX SBOM 生成。

镜像值见 [`application-images.env`](application-images.env)。它可以作为客户 `compose/.env` 或 Kubernetes
发布参数的输入，但**不是完整部署配置**：PostgreSQL、MinIO、Nessie、TuGraph、Doris、Kafka 和 Redis
仍必须使用同一客户包批准的不可变摘要。

当前边界：

- 四个 GHCR 镜像均为 Public，并已按 RepoDigest 完成无登录凭据的匿名读取验证；
- 根目录状态仍为 `PREPARED`，不得执行正式安装；
- Docker Compose 客户包仍等待全部基础设施摘要和最终放行证据；
- Kubernetes 仍为参考实施，不属于自助交付 `GO` 范围。
