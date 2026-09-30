# 日常运维

[English](operations.en.md) | 简体中文

## 状态与健康检查

```bash
bash compose/manage.sh status
bash compose/manage.sh health
bash compose/manage.sh logs platform-api
```

建议由客户监控系统持续检查 UI、API、容器状态、磁盘使用率、证书有效期、License 有效期和 Flink 任务状态。日志应采集到客户日志平台，并按数据合规要求设置保留期。

生成默认脱敏的诊断报告：

```bash
bash scripts/collect-diagnostics.sh
```

报告保存在 `diagnostics/`，不包含 `.env` 内容、License、容器环境变量或应用日志。对外发送前仍需客户审阅。

## 启停

```bash
bash compose/manage.sh stop
bash compose/manage.sh start
bash compose/manage.sh restart-api
```

`stop` 和 `down` 均保留数据卷。不要执行带 `--volumes` 的删除命令。计划停机前应停止业务写入、确认 Flink 作业状态并完成备份。

## 日志

```bash
bash compose/manage.sh logs
bash compose/manage.sh logs platform-api
bash compose/manage.sh logs platform-ui
```

提交支持工单时提供问题时间段、版本、相关服务日志和操作步骤。删除访问令牌、密码、License 全文及业务敏感数据后再传输日志。

## 容量管理

重点监控 Docker 数据目录、PostgreSQL、RustFS 对象与日志卷、Doris、Kafka 和 Flink 制品目录。磁盘使用率达到客户预警阈值时，应先确认增长来源，再执行经批准的归档或扩容；不得直接删除容器卷中的文件。

## 变更管理

所有镜像、配置、证书、网络和密钥变更必须记录变更单、回滚条件和验证结果。禁止直接进入容器修改配置，因为容器重建会丢失此类变更。
