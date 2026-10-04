# 安装指南

[English](getting-started.en.md) | 简体中文

本文说明如何在客户自有 Linux 主机上安装 Coomia AI Data Platform。生产安装前必须完成容量、安全、备份和变更审批。

## 1. 支持范围

- 操作系统：主流 Linux amd64 发行版。
- 容器运行时：Docker Engine 与 Docker Compose v2。
- 推荐资源：不少于 8 vCPU、16 GiB 内存和 50 GiB 可用磁盘；生产容量应根据数据量另行评估。
- 网络：主机可访问交付方镜像仓库和 License 服务；离线授权除外。
- 权限：安装用户可访问 Docker，并拥有三个客户数据目录。

Kubernetes 清单目前为参考实现，不属于无人值守标准安装路径。详见 [Kubernetes 说明](../kubernetes/README.md)。

## 2. 发布材料验收

安装前确认：

1. `RELEASE_STATUS` 为交付方批准的状态。
2. `VERSION` 与发布清单一致。
3. 所有镜像均使用 `@sha256:` RepoDigest，不接受浮动 tag。
4. 软件包校验和与交付方提供的 `SHA256SUMS` 一致。
5. 已获得适用环境的 License 文件或在线授权信息。

共享镜像摘要由 [`CURRENT_RELEASE`](../CURRENT_RELEASE) 指向的版本目录统一固定。普通试用用户无需从官网
复制或选择镜像；只有交付方明确提供客户专有镜像时才覆盖默认值。发布状态门禁仍然独立生效，
`PREPARED` 状态不能启动安装。

## 3. 初始化配置

```bash
bash scripts/preflight-linux.sh compose
bash scripts/init-config.sh
vi compose/.env
```

`init-config.sh` 会载入当前版本的共享固定镜像、生成随机凭据，并将 `compose/.env` 权限设置为 `0600`。
检查主机目录、端口、网段和 License 模式；仅在收到客户专有镜像交付时覆盖镜像字段。完整参数见
[配置参考](configuration.md)。

## 4. 安装

```bash
bash install.sh compose
```

安装器会依次校验配置、拉取固定摘要镜像、验证 Flink 运行镜像、生成 Doris 密码配置、解析 Compose 清单并等待服务健康。任一步骤失败都会停止安装并返回非零状态。

## 5. 首次管理员

1. 打开 `http://<服务器地址>:3000` 注册第一个账号。
2. 执行 `bash compose/manage.sh restart-api`。
3. 使用第一个账号登录。
4. 在授权管理页面导入或激活 License。

仅当系统中不存在管理员时，API 启动过程才会将最早注册账号提升为平台管理员。不要在公网开放注册期间执行该流程。

## 6. 验收

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
```

验收至少包括：登录、License 状态、数据源连接、测试管道提交、Flink 作业状态、对象存储写入和日志无持续错误。验收结果应与版本号、镜像摘要和执行时间一起归档。

## 7. 下一步

- [日常运维](operations.md)
- [升级、备份与回滚](upgrade-and-backup.md)
- [安全说明](security.md)
- [故障排查](troubleshooting.md)
