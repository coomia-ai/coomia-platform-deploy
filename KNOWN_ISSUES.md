# 已知限制

[English](KNOWN_ISSUES.en.md) | 简体中文

## 当前发布准备项

- `trial.11` API/UI 已在厂商隔离 K8s 环境运行，License 激活、UI 代理、API 健康、Doris 登录和
  Flink Local/K8s JAR 一致性已通过。新 `trial.11` Flink 作业已达到 `RUNNING/READY/STABLE`，
  checkpoint 持续增长，并通过最终 savepoint 暂停。
- 核心业务验收被项目级凭据门禁阻断。新项目正确进入 `CREDENTIALS_REQUIRED`，但当前客户包没有自动
  创建 Doris、对象存储和 TuGraph 最小权限主体及其 Kubernetes Secret 的工具。手工只创建 Secret
  不能证明后端主体真实存在，也不能作为自助交付方案。状态继续保持 `PREPARED` / `REFERENCE_ONLY`。
- Docker Compose 验证已暂停。此前 `trial.7` 的 1 天 License 到期、最终 savepoint 和自动暂停证据继续
  保留，但不能替代 `trial.11` 核心业务验收。
- `trial.6` 旧候选包含 TuGraph 3.5.0，缺少平台所需 Bolt 接口，必须废弃且不得交付。
- RustFS 使用新的 `coomia-object-storage-data` 数据卷。旧 MinIO 数据卷不能直接挂载到 RustFS；已有环境
  如需迁移，必须执行单独设计、备份验证和对象级迁移，不能按普通原地升级处理。
- Kubernetes 内容仅提供 API 与 Flink 隔离参考，不包含完整 UI、Ingress/TLS、监控、备份和全部基础设施安装，因此不属于标准自助交付路径。

## 产品化边界

- Docker Compose 路径面向单机部署，不提供组件级高可用。需要高可用、跨主机调度或灾备切换的客户应采用经专项设计的 Kubernetes 方案。
- TLS、域名、外部身份认证、集中日志、监控告警和备份存储由客户基础设施提供。
- 首次安装注册第一个账号后，需要重启一次 API 才会完成首个管理员初始化。

以上限制不代表允许跳过 [发布准入条件](docs/release-readiness.md)。正式版本的新增问题应记录影响、规避措施、修复计划和客户批准。
