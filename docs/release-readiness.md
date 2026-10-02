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

本目录当前为 `PREPARED`。`trial.11` 候选摘要记录在 `releases/2026.10.01-trial.11/`。匿名读取、隔离
K8s API/UI、Doris 登录和 Flink 镜像内 JAR 一致性已有证据；新 Flink 作业、核心业务回归和正式安全/SBOM
证据归档仍待完成。Docker Compose 验证已暂停。Kubernetes 仍为参考实现，当前包不得宣称为已批准
生产版本，也不得提供自助安装下载。

## 证据归档

交付方应基于 [发布清单模板](../release-manifest.example.md) 生成实际版本清单，并与 `VERSION`、`CHANGELOG`、`KNOWN_ISSUES`、`SHA256SUMS`、签名和测试报告一起归档。客户侧也应保存收到的原始材料。

## 状态变更

将状态改为 `GO` 前，发布负责人必须确认所有准入项有可追溯证据。任何镜像、脚本或清单变更都会使既有证据失效，必须重新执行相关验证。
