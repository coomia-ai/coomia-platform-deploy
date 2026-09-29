# 故障排查

[English](troubleshooting.en.md) | 简体中文

排障前记录故障时间、版本、最近变更和影响范围。不要通过删除数据卷、重建数据库或关闭安全控制来试错。

## 安装器拒绝镜像

确认镜像值非空并使用 `仓库/镜像@sha256:<64 位小写摘要>`。安装器不会接受 tag。

## UI 返回 502 或 503

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
bash compose/manage.sh logs platform-ui
```

503 首先表示应用或上游服务不可用，不能直接判断为 License 到期。检查 API 健康、容器重启、数据库连接、磁盘空间和反向代理配置。

## 注册后无法登录

首次部署应先注册第一个账号，再执行：

```bash
bash compose/manage.sh restart-api
```

随后使用最早注册账号登录。若已有管理员，不会再次自动提升账号。

## License 导入失败

确认文件来自当前环境的正式签发流程、未被修改且未绑定其他实例。离线模式还需确认公钥路径、挂载权限和系统时间。保留 API 日志中的错误码，但不要传输完整 License。

## Flink 任务异常

检查 API 和 Flink 网关日志、Docker 套接字权限、控制令牌、制品目录权限和磁盘空间。不要手工删除 Flink 作业容器；先通过平台停止或取消任务并确认状态收敛。

## 基础设施异常

使用 `status` 找出非健康服务，再查看单个服务日志。若出现磁盘满、数据库损坏或持续重启，停止写入并进入恢复流程，不要直接清理卷内容。
