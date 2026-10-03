# Kubernetes 部署参考

[English](README.en.md) | 简体中文

本目录提供 platform-api 与 Flink 工作负载隔离的安全参考，不是完整的一键 Kubernetes 产品安装包。它假设客户已经具备生产 Kubernetes、持久化存储、Ingress/TLS、Flink Kubernetes Operator、PostgreSQL、MinIO、Doris、Kafka、Redis、Nessie 与 TuGraph。

当前状态为 `REFERENCE_ONLY`。未经交付方联合评审，不应直接应用到客户生产集群。安装器只有在 `KUBERNETES_STATUS=GO` 后才会执行。

当前 `trial.14` 候选摘要见 [`../releases/2026.10.03-trial.14/`](../releases/2026.10.03-trial.14/)。API/UI、
License 激活、Doris 登录、Flink 运行/checkpoint/savepoint，以及项目级 Doris、对象存储和 TuGraph
凭据自动创建、失败恢复、轮换、跨项目隔离、旧代次吊销和删除清理已经通过隔离 K8s 验收。完整核心业务、
备份恢复和客户基础设施产品化尚未完成，因此不得改为 `GO`。

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
