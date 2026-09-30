# 2026.09.30-trial.6 应用镜像

[English](README.en.md) | 简体中文

本目录记录公共试用版本的一方应用镜像 RepoDigest。四个镜像已经完成 Linux/amd64 构建、保护检查、
推送前与 RepoDigest 回拉后的 Critical/secret 门禁，以及 CycloneDX SBOM 生成。

一方镜像值见 [`application-images.env`](application-images.env)，Compose 基础设施摘要见
[`infrastructure-images.env`](infrastructure-images.env)。两者是客户配置的发布输入，但只有发布工程生成、
校验并最终批准的客户包才允许安装。

当前边界：

- 四个 GHCR 镜像均为 Public，并已按 RepoDigest 完成无登录凭据的匿名读取验证；
- 根目录状态仍为 `PREPARED`，不得执行正式安装；
- Compose 基础设施镜像已经固定摘要；RustFS 1.0.0 已通过 Critical/secret、SBOM、S3 API 与健康端点验证；
- Docker Compose 客户包仍等待完整候选包验证和最终放行证据；
- Kubernetes 仍为参考实施，不属于自助交付 `GO` 范围。
