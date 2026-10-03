# 2026.10.03-trial.14 K8s 项目凭据验收候选

[English](README.en.md) | 简体中文

本目录记录公共试用 `trial.14` 的不可变镜像摘要。API 使用源码提交
`13de75d82a9ca1ccad1376d9661c2b4d1ea7c34a` 构建的新加密镜像；UI、Flink Local 和 Flink K8s
继续使用已通过 `trial.11` 验收的摘要，因此这是 API 热修候选而不是四镜像重建版本。

`trial.14` API 已通过保护构建、推送前与 RepoDigest 回读后 Critical/Secret 门禁、匿名拉取和双 SBOM
检查。厂商隔离 K8s 环境使用本目录 API 与 Flink K8s 摘要完成项目凭据自动创建、失败恢复、轮换、
Doris/对象存储/TuGraph 跨项目隔离、旧代次吊销和删除清理验收。

Docker Compose 未启动且验证继续暂停；完整核心业务、备份恢复和客户环境安装也尚未通过。根目录与
Kubernetes 状态保持 `PREPARED` / `REFERENCE_ONLY`，本目录不授予交付 `GO`。
