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
- `20-classic-enterprise-api.yaml`、`21-classic-enterprise-flink-namespace.yaml`、`22-classic-enterprise-ui.yaml` 与 `render-enterprise.sh`：Enterprise 独立部署参考。渲染器只生成并校验清单，不执行 `kubectl apply`；它同时生成独立 API/UI/Flink namespace、selector、License PVC 和版本身份。只有提供不可变 UI 镜像时，外部根路径才会指向 UI Service。
- `snapshot-enterprise.sh`、`verify-enterprise-isolation.sh`、`rollback-enterprise.sh` 与 `rollback-enterprise-ui.sh`：只导出非敏感元数据的快照 helper、只读的现场隔离/身份/就绪校验 helper，以及带显式确认和完整 API/UI 发布身份校验的回滚 helper；均不会自动部署。
- `enterprise-operations.md`：Enterprise 候选的预检、快照、发布和回滚操作步骤。

Enterprise 清单必须使用 `CLASSIC_ENTERPRISE_API_IMAGE` 指定不可变 RepoDigest，并同时提供
独立的 `CLASSIC_ENTERPRISE_UI_IMAGE` RepoDigest（不能复用 `PLATFORM_UI_IMAGE`），并同时提供
`CLASSIC_ENTERPRISE_CORE_REVISION`、`CLASSIC_ENTERPRISE_ENTERPRISE_REVISION`、
`CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION` 和 `CLASSIC_ENTERPRISE_RELEASE_INPUTS`。渲染器会把这些
身份写入 Namespace、Deployment 和 Pod 标签；完整 64 位组合 digest 写入 annotations，标签使用其 63 位前缀。还需将 `classic-enterprise-api-secret`、
`classic-enterprise-schema-baseline` 和独立数据库连接准备在目标 namespace，并为 Secret 与 schema baseline 设置
`coomia.com/data-scope=enterprise`。Secret 必须包含非空数据库、对象存储、图、缓存、JWT 和 delivery-HMAC 键；只读校验器只检查元数据与键存在性，不输出 Secret 值。它不会复用
`mds-app/platform-api` 的 Service、selector、License PVC 或配置。渲染结果会同时创建 API 与 Flink namespace；Flink namespace 只声明 Enterprise 专属边界，运行时 RBAC/Operator 策略仍需由目标集群按安全基线预置。两个 namespace 都会拒绝
`mds-app`、`mds-flink`、`data-infra` 和历史验收 namespace `mds-m2-acceptance`，避免渲染结果误指向 M2 共享环境。
渲染示例：

```bash
CLASSIC_ENTERPRISE_API_IMAGE=ghcr.io/example/coomia-enterprise@sha256:<digest> \
CLASSIC_ENTERPRISE_UI_IMAGE=ghcr.io/example/coomia-enterprise-ui@sha256:<digest> \
CLASSIC_ENTERPRISE_CORE_REVISION=<core-revision> \
CLASSIC_ENTERPRISE_ENTERPRISE_REVISION=<enterprise-revision> \
CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION=<deployment-revision> \
CLASSIC_ENTERPRISE_RELEASE_INPUTS=<64-char-input-digest> \
  bash kubernetes/render-enterprise.sh /tmp/classic-enterprise.yaml
```

默认不会渲染外部 Ingress。经过域名、TLS Secret、网络策略和业务验收授权后，同时提供
`CLASSIC_ENTERPRISE_INGRESS_HOST`、`CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET` 和
Ingress controller 所在的 `CLASSIC_ENTERPRISE_INGRESS_NAMESPACE`，渲染器才会加入
独立的 `classic-enterprise-api` Ingress，并保留 `/api/copilotkit` 与 `/` 路由。渲染不会修改 DNS、Secret
或集群；Ingress namespace 未提供时会直接失败，并且 NetworkPolicy 只允许该 namespace 的 controller 访问。

渲染完成不代表部署、迁移、回滚或域名验收通过；这些仍需授权环境中的独立证据。

参考安装器会从 [`CURRENT_RELEASE`](../CURRENT_RELEASE) 自动载入以下共享发布变量，且镜像必须为不可变
RepoDigest：

- `PLATFORM_API_IMAGE`
- `FLINK_K8S_IMAGE`
- `K8S_PROBE_IMAGE`
- `FLINK_UNIFIED_ARTIFACT_SHA256`

公共试用镜像使用 `ghcr.io/coomia-ai/...@sha256:...`，不需要镜像拉取 Secret。
普通试用用户不需要从官网复制摘要；只有交付方明确签发客户专有镜像时才通过环境变量覆盖默认值。
只有改用私有 Registry 时，才设置 `PLATFORM_API_IMAGE_PULL_SECRET` 和 `FLINK_K8S_IMAGE_PULL_SECRET`，
安装器会验证 Secret 已分别存在于 `mds-app` 和 `mds-flink`。

生产实施必须由客户平台团队与交付方共同完成容量、存储类、网络策略、备份、升级和灾难恢复评审。
