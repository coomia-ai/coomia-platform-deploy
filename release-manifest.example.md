# 发布清单模板

[English](release-manifest.example.en.md) | 简体中文

> 本文件是模板。正式发布时复制为 `release-manifest.md`，由发布负责人填写并签署。所有镜像字段当前按要求留空。

| 字段 | 值 |
|---|---|
| 版本 |  |
| 发布日期 |  |
| 发布负责人 |  |
| 发布状态 |  |
| 支持的部署方式 |  |

## 镜像

| 组件 | 不可变 RepoDigest | SBOM | 签名验证证据 |
|---|---|---|---|
| platform-api |  |  |  |
| platform-ui |  |  |  |
| Flink runtime |  |  |  |
| PostgreSQL |  |  |  |
| MinIO / mc |  |  |  |
| Nessie |  |  |  |
| TuGraph |  |  |  |
| Doris FE / BE |  |  |  |
| Kafka |  |  |  |
| Redis |  |  |  |

## 发布证据

| 检查项 | 证据位置 | 结果 |
|---|---|---|
| 产品镜像源码残留扫描 |  |  |
| 漏洞与恶意软件扫描 |  |  |
| 全新空环境安装 |  |  |
| 首次管理员与 License 激活 |  |  |
| 核心业务验收 |  |  |
| 升级与回滚 |  |  |
| 备份与恢复 |  |  |
| 已知问题审批 |  |  |

## 包完整性

| 项目 | 值 |
|---|---|
| `SHA256SUMS` |  |
| 软件包签名 |  |
| `bash scripts/verify-package.sh` |  |

发布批准人：

批准时间：

签名或审批记录：
