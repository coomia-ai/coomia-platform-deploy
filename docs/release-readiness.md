# 发布完整性与准入

[English](release-readiness.en.md) | 简体中文

`RELEASE_STATUS` 是交付包的发布门禁。`PREPARED` 表示结构、文档和候选镜像可以已经准备完成，但仍缺少一项或多项最终验收证据；只有交付方审核后才能改为 `GO`。

## 发布准入条件

- 所有镜像字段均为批准的不可变 RepoDigest。
- 产品镜像通过源码残留扫描、恶意软件扫描和漏洞评估。
- SBOM、镜像签名和校验和已生成并验证。
- 全新空环境安装、首次管理员、License 激活和基础业务验收通过。
- 升级、回滚、备份和恢复演练通过。
- 已知问题已评估并获得发布批准。
- `bash scripts/verify-package.sh` 返回成功。

验收证据必须明确覆盖 PostgreSQL 空卷初始化、首个平台注册用户、全部基础设施镜像、数据库迁移兼容性、platform-ui 可用性以及 Ingress/TLS 责任边界。

## 当前状态

本目录当前为 `PREPARED`。通用 `compose/.env.example` 的镜像字段有意留空；`trial.7` 已批准候选摘要记录在
`releases/2026.09.30-trial.7/`，由客户在初始化后的私有 `compose/.env` 中配置。镜像安全门禁、匿名拉取、
厂商隔离 K8s 全栈、1 天 License 到期和 Flink 最终 savepoint 后自动暂停均已有验证证据；客户 Compose
干净 Linux 主机完整安装和业务冒烟验收尚未完成。Kubernetes 仍为参考实现。当前包不得对客户宣称为
已批准生产版本，也不得提供自助安装下载。

## 证据归档

交付方应基于 [发布清单模板](../release-manifest.example.md) 生成实际版本清单，并与 `VERSION`、`CHANGELOG`、`KNOWN_ISSUES`、`SHA256SUMS`、签名和测试报告一起归档。客户侧也应保存收到的原始材料。

## 状态变更

将状态改为 `GO` 前，发布负责人必须确认所有准入项有可追溯证据。任何镜像、脚本或清单变更都会使既有证据失效，必须重新执行相关验证。
