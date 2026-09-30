# 部署架构

[English](architecture.en.md) | 简体中文

## 目标拓扑

标准 Docker Compose 部署运行在一台客户管理的 Linux 主机上。外部流量只进入 platform-ui 和 platform-api；数据与流处理组件位于内部容器网络。

```text
用户 / 客户反向代理
        |
        +-- platform-ui :3000
        +-- platform-api :8050
                  |
        +---------+-------------------------------+
        | PostgreSQL | RustFS | Nessie | TuGraph |
        | Doris FE/BE | Kafka | Redis             |
        +-----------------------------------------+
                  |
        认证的 Flink Docker 网关 -> Flink 作业容器
```

客户反向代理负责正式域名、TLS 证书、访问策略和流量日志。部署包不自动修改 DNS、防火墙或主机证书。

## 网络分区

- `mds-frontend`：UI 与 API 通信。
- `mds-data`：PostgreSQL、RustFS S3、Nessie、TuGraph、Doris 与 API 通信。
- `mds-streaming`：Kafka、Redis 与 API 通信。
- `coomia-flink-control`：API 与 Flink Docker 网关的内部控制网络。

基础设施服务默认不发布到主机。`docker-compose.admin.yml` 仅用于本机临时排障，并绑定 `127.0.0.1`。

## 对外端口

| 服务 | 默认主机端口 | 用途 |
|---|---:|---|
| platform-ui | 3000 | 用户界面 |
| platform-api | 8050 | API 与健康检查 |

生产环境通常只允许反向代理访问以上端口。实际防火墙策略由客户安全基线决定。

## 持久化边界

Compose 命名卷保存 PostgreSQL、RustFS 对象、RustFS 日志、Doris、Kafka、Redis、TuGraph 和 License 状态。三个客户目录保存 Flink 制品、生成配置和项目级接入密钥。容器删除不等于数据删除，但删除命名卷会造成不可逆数据丢失。

## 可用性边界

标准 Compose 路径是单主机架构，不提供跨主机高可用。主机故障恢复依赖客户备份和恢复流程。需要高可用或灾备切换时，必须采用经过专项设计和验证的 Kubernetes 架构。

## 信任边界

Flink Docker 网关是唯一可访问只读 Docker 套接字的服务，并使用独立控制令牌和内部网络。Docker 套接字仍属于主机高权限接口，因此主机管理员、Docker 组成员和网关令牌都应按照特权身份管理。
