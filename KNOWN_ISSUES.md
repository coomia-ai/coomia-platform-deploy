# 已知限制

[English](KNOWN_ISSUES.en.md) | 简体中文

## 当前发布准备项

- `trial.7` 一方镜像和厂商隔离 K8s 全栈已通过验证，包含稳定机器指纹修复、PostgreSQL 16.14 与
  TuGraph 4.5.1。客户 Compose 仍使用独立的 Apache Kafka 镜像契约，尚未在全新 Linux 主机完成完整
  首装以及 Nessie/Iceberg/Flink 和核心业务冒烟验收，因此状态保持 `PREPARED`。1 天 License 到期、
  最终 savepoint 和 Flink 自动暂停已于 2026-10-02 在厂商隔离环境通过，不再作为独立阻塞项。
- `trial.6` 旧候选包含 TuGraph 3.5.0，缺少平台所需 Bolt 接口，必须废弃且不得交付。
- RustFS 使用新的 `coomia-object-storage-data` 数据卷。旧 MinIO 数据卷不能直接挂载到 RustFS；已有环境
  如需迁移，必须执行单独设计、备份验证和对象级迁移，不能按普通原地升级处理。
- Kubernetes 内容仅提供 API 与 Flink 隔离参考，不包含完整 UI、Ingress/TLS、监控、备份和全部基础设施安装，因此不属于标准自助交付路径。

## 产品化边界

- Docker Compose 路径面向单机部署，不提供组件级高可用。需要高可用、跨主机调度或灾备切换的客户应采用经专项设计的 Kubernetes 方案。
- TLS、域名、外部身份认证、集中日志、监控告警和备份存储由客户基础设施提供。
- 首次安装注册第一个账号后，需要重启一次 API 才会完成首个管理员初始化。

以上限制不代表允许跳过 [发布准入条件](docs/release-readiness.md)。正式版本的新增问题应记录影响、规避措施、修复计划和客户批准。
