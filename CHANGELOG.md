# 变更记录

[English](CHANGELOG.en.md) | 简体中文

## 0.2.0-prepared - 2026-09-29

- 重构为可独立建仓的客户部署包，应用镜像地址保持为空。
- 增加自动生成强随机凭据的配置初始化脚本和统一运维入口。
- Compose 全面使用不可变 RepoDigest 校验，基础设施端口默认不对外暴露。
- 移除演示数据、Kafka 主题清理、公开对象存储桶和默认业务密码。
- 修复 PostgreSQL 空卷初始化，收敛 Doris、Flink 和离线 License 配置。
- 增加中英文安装、配置、License、运维、升级、备份、安全、排障和发布准入文档。
- 增加客户包静态安全检查和发布状态门禁。
- 增加 `AGENTS.md`、`llms.txt`、中英文 AI 运维指南、机器可读配置 Schema 和脱敏诊断脚本。

当前状态为 `PREPARED`，不代表已填入正式镜像或已通过客户生产发布审批。

## 0.1.0-preview - 2026-09-28

- 建立初始客户部署目录和 Compose/Kubernetes 草案。
