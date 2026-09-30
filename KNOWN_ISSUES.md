# 已知限制

[English](KNOWN_ISSUES.en.md) | 简体中文

## 当前发布准备项

- `trial.6` 的应用与 Compose 基础设施镜像摘要已经确认。对象存储已从未通过 Critical 门禁的旧 MinIO
  镜像切换为 RustFS 1.0.0；在完成空环境 Compose 安装、Nessie/Iceberg/Flink 联调和最终发布审批前，
  本目录状态保持 `PREPARED`。
- RustFS 使用新的 `coomia-object-storage-data` 数据卷。旧 MinIO 数据卷不能直接挂载到 RustFS；已有环境
  如需迁移，必须执行单独设计、备份验证和对象级迁移，不能按普通原地升级处理。
- Kubernetes 内容仅提供 API 与 Flink 隔离参考，不包含完整 UI、Ingress/TLS、监控、备份和全部基础设施安装，因此不属于标准自助交付路径。

## 产品化边界

- Docker Compose 路径面向单机部署，不提供组件级高可用。需要高可用、跨主机调度或灾备切换的客户应采用经专项设计的 Kubernetes 方案。
- TLS、域名、外部身份认证、集中日志、监控告警和备份存储由客户基础设施提供。
- 首次安装注册第一个账号后，需要重启一次 API 才会完成首个管理员初始化。

以上限制不代表允许跳过 [发布准入条件](docs/release-readiness.md)。正式版本的新增问题应记录影响、规避措施、修复计划和客户批准。
