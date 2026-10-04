# 变更记录

[English](CHANGELOG.en.md) | 简体中文

## 0.2.7-prepared - 2026-10-04

- 固定 `trial.22` 四个一方镜像 RepoDigest 和 Unified Intake 制品摘要；
- 记录隔离 K8s 项目凭据轮换、自动 savepoint 升级、对象/checkpoint/Iceberg/Action 核心链路通过；
- 记录 PostgreSQL/Nessie、对象存储、Doris、TuGraph、Kafka、Redis 和 License 状态的应用级恢复通过；
- 根状态页改为以生成的 release manifest 为准；Compose、客户基础设施灾备、全产品回归和人工批准仍待完成。

## 0.2.6-prepared - 2026-10-03

- 固定 `trial.14` 加密 API RepoDigest，UI 与 Flink 继续沿用已验收的 trial.11 摘要；
- 记录 API 双阶段安全门禁、匿名拉取、双 SBOM 和隔离 K8s 项目凭据生命周期验收通过；
- 更新中英文发布状态与镜像目录；Compose、核心业务、备份恢复和人工批准仍待完成。

## 0.2.5-prepared - 2026-10-03

- Compose/Kubernetes 清单已接入项目凭据自动生命周期：创建时生成并验证 Doris、对象存储和 TuGraph 最小权限身份，轮换时协调 Flink 后撤销旧代次，删除时清理全部受系统管理的保留代次；
- 项目凭据持久化目录改为 API 独占读写；Kubernetes 代码只按确定名称访问 Secret，RBAC 增加轮换所需的 `update`，仍不允许 `list`、`watch` 或 `patch`；
- 源码与静态交付门禁已完成，但当前 `trial.11` 镜像不包含本次实现，必须发布新不可变镜像并完成隔离 K8s 运行验收后才能放行，因此状态继续保持 `PREPARED` / `REFERENCE_ONLY`。

## 0.2.4-prepared - 2026-10-02

- 新增 `trial.11` 四个一方应用镜像的不可变 GHCR 摘要和对应制品哈希；
- 在厂商隔离 K8s 环境完成 API/UI、UI 代理、Doris 登录及 Flink Local/K8s JAR 一致性验证；
- Docker Compose 验证暂停，新的 Flink 作业和核心业务回归仍待完成，因此继续保持 `PREPARED` / `REFERENCE_ONLY`。

## 0.2.3-prepared - 2026-09-30

- 发布修复多 Worker 首次启动机器指纹竞态的加密 API 镜像，并同步 UI、Flink Local、Flink K8s 不可变摘要；
- 四个 GHCR 包完成推送前和推送后安全门禁、SBOM 生成及无凭据匿名读取验证；
- 更新 PostgreSQL 16.14 与 TuGraph 4.5.1 摘要，记录厂商隔离 K8s 全栈验收通过；
- 2026-10-02 在厂商隔离环境通过 1 天 License 到期、最终 savepoint 和 Flink 自动暂停验收；保持
  `PREPARED`，等待客户 Compose 干净 Linux 主机完整安装和业务冒烟验收。

## 0.2.2-prepared - 2026-09-30

- 将 Compose 对象存储从存在未修复 Critical 漏洞的 MinIO 镜像切换为 RustFS 1.0.0 固定摘要；
- 移除独立 `mc` 镜像，复用受保护的 platform-api 镜像通过标准 S3 API 幂等创建私有 bucket；
- 增加完整基础设施摘要目录，并同步安装校验、Schema、中英文文档和发布清单。

## 0.2.1-prepared - 2026-09-30

- 记录 `trial.6` 四个一方应用镜像的不可变 GHCR RepoDigest；
- 保持通用模板为空，并明确完整客户包仍等待基础设施摘要、Public 可见性和最终放行。

## 0.2.0-prepared - 2026-09-29

- 重构为可独立建仓的客户部署包，应用镜像地址保持为空。
- 增加自动生成强随机凭据的配置初始化脚本和统一运维入口。
- Compose 全面使用不可变 RepoDigest 校验，基础设施端口默认不对外暴露。
- 移除演示数据、Kafka 主题清理、公开对象存储桶和默认业务密码。
- 修复 PostgreSQL 空卷初始化，收敛 Doris、Flink 和离线 License 配置。
- 增加中英文安装、配置、License、运维、升级、备份、安全、排障和发布准入文档。
- 增加客户包静态安全检查和发布状态门禁。
- 增加 `AGENTS.md`、`llms.txt`、中英文 AI 运维指南、机器可读配置 Schema 和脱敏诊断脚本。

当前状态为 `PREPARED`，不代表已通过客户生产发布审批。

## 0.1.0-preview - 2026-09-28

- 建立初始客户部署目录和 Compose/Kubernetes 草案。
