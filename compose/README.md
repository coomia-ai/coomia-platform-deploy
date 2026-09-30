# Docker Compose 部署

[English](README.en.md) | 简体中文

Docker Compose 是本交付包的推荐部署方式。默认只暴露 UI 和 API；PostgreSQL、RustFS 对象存储、Nessie、Doris、Kafka、Redis 与 TuGraph 仅在内部网络中可访问。

```bash
bash ../scripts/init-config.sh
vi .env
cd ..
bash install.sh compose
```

安装器会校验所有镜像 RepoDigest、密钥长度、目录所有权、Flink JAR 摘要、Flink 非 root UID/GID、Doris 初始密码以及最终 Compose 配置。详细流程见[安装指南](../docs/getting-started.md)。

需要从宿主机临时访问基础设施管理端口时，显式追加 `docker-compose.admin.yml`，所有端口只绑定到 `127.0.0.1`。不要在公网主机上修改为 `0.0.0.0`。
