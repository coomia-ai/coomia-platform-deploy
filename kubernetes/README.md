# Kubernetes 部署参考

[English](README.en.md) | 简体中文

本目录提供 platform-api 与 Flink 工作负载隔离的安全参考，不是完整的一键 Kubernetes 产品安装包。它假设客户已经具备生产 Kubernetes、持久化存储、Ingress/TLS、Flink Kubernetes Operator、PostgreSQL、MinIO、Doris、Kafka、Redis、Nessie 与 TuGraph。

当前状态为 `REFERENCE_ONLY`。未经交付方联合评审，不应直接应用到客户生产集群。安装器只有在 `KUBERNETES_STATUS=GO` 后才会执行。

当前候选摘要以生成包的 `release-manifest.md` 和对应 `releases/<version>/` 目录为准。`trial.22` 已通过
隔离 K8s 的 License、项目凭据生命周期、Flink savepoint 升级、对象/checkpoint/Iceberg/Action 核心链路，
以及 PostgreSQL、Nessie、对象存储、Doris、TuGraph、Kafka、Redis 和 License 状态的应用级恢复验收。
完整自助安装器、全产品回归和人工批准尚未完成，因此不得改为 `GO`。

现有内容包括：

- `10-platform-api.yaml`：API、License PVC、ServiceAccount 和 Flink 控制面 RBAC；
- `mds-flink-namespace.yaml`：Flink namespace、最小运行权限和准入隔离策略；
- `apply-flink-isolation.sh`：应用并验证准入策略；
- `install.sh`：校验镜像摘要、Secret 和清单后执行部署。

参考安装器要求显式提供以下发布变量，且镜像必须为不可变 RepoDigest：

- `PLATFORM_API_IMAGE`
- `FLINK_K8S_IMAGE`
- `K8S_PROBE_IMAGE`
- `FLINK_UNIFIED_ARTIFACT_SHA256`

公共试用镜像使用 `ghcr.io/coomia-ai/...@sha256:...`，不需要镜像拉取 Secret。
只有改用私有 Registry 时，才设置 `PLATFORM_API_IMAGE_PULL_SECRET` 和 `FLINK_K8S_IMAGE_PULL_SECRET`，
安装器会验证 Secret 已分别存在于 `mds-app` 和 `mds-flink`。

生产实施必须由客户平台团队与交付方共同完成容量、存储类、网络策略、备份、升级和灾难恢复评审。
