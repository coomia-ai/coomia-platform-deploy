# 2026.10.01-trial.11 K8s 验收候选

[English](README.en.md) | 简体中文

本目录记录公共试用 `trial.11` 的不可变镜像摘要。四个 GHCR 镜像均已按 RepoDigest 完成无凭据匿名读取，
目标平台为 `linux/amd64`。厂商隔离 K8s 环境已运行本目录的 API 和 UI 摘要，并通过 UI 代理、API 健康和
Doris 登录检查。

Flink Local 与 Flink K8s 镜像内的 Unified Intake JAR 摘要均为
`d04fe2680409abdf38891817c7444e0fb68281b6862afc205170713663cb3125`，SQL Runner JAR 摘要均为
`8694f78b9d10b71c7b83e550c132572e1fe140a29520c8c035a207efdc74c491`。

新 `trial.11` Flink 作业已达到 `RUNNING/READY/STABLE`，checkpoint 从 17 增至 23 且失败数未增长，
对象存储中存在 checkpoint 元数据与共享对象，最终 savepoint 后成功暂停。核心业务回归被项目级凭据
自动化缺失阻断；正式安全扫描/SBOM 证据归档仍待完成，Compose 验证已暂停。根目录与 Kubernetes
状态保持 `PREPARED` / `REFERENCE_ONLY`，本目录不授予交付 `GO`。
