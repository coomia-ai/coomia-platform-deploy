# 2026.09.30-trial.7 公共试用候选

[English](README.en.md) | 简体中文

本目录记录公共试用 `trial.7` 的不可变镜像摘要。该版本在 `trial.6` 基础上修复 API 多进程首次启动时
机器指纹文件的并发创建问题。四个一方镜像已经完成 Linux/amd64 构建、源码保护检查、推送前与
RepoDigest 回拉后的 Critical/secret 门禁、CycloneDX SBOM 生成和 GHCR 匿名读取验证。

一方镜像值见 [`application-images.env`](application-images.env)，Compose 基础设施摘要见
[`infrastructure-images.env`](infrastructure-images.env)。两者是客户配置的发布输入，但只有发布工程生成、
校验并最终批准的客户包才允许安装。

当前边界：

- 四个 GHCR 镜像均为 Public，并已按 RepoDigest 完成无登录凭据的匿名读取验证；
- 厂商隔离 K8s 全栈已验证 PostgreSQL、RustFS、Nessie、TuGraph 4.5.1、Doris、Kafka、Redis、API 和 UI；
- API 两个 Worker 使用同一稳定机器指纹，授权状态接口正常；
- 1 天 License 生命周期、最终 savepoint 和 Flink 到期自动暂停已于 2026-10-02 在厂商隔离环境通过；
- 根目录状态仍为 `PREPARED`，客户 Compose 干净 Linux 主机安装和业务冒烟验收仍需完成；
- Kubernetes 仍为参考实施，不属于自助交付 `GO` 范围。
