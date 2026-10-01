# 配置参考

[English](configuration.en.md) | 简体中文

客户配置文件为 `compose/.env`。该文件包含凭据，权限必须为 `0600`，不得提交到 Git、工单或聊天记录。

机器可读配置契约位于 [`schemas/compose-env.schema.json`](../schemas/compose-env.schema.json)。该 Schema 面向解析后的客户配置；交付模板中的镜像空值在正式安装前必须由批准的 RepoDigest 替换。

## 镜像

`PLATFORM_API_IMAGE`、`PLATFORM_UI_IMAGE`、`FLINK_LOCAL_IMAGE` 以及全部基础设施镜像变量必须由交付方填写。值必须是完整 RepoDigest：

公共试用应用镜像来自 `ghcr.io/coomia-ai`，例如：

```text
PLATFORM_API_IMAGE=ghcr.io/coomia-ai/coomia-platform-api@sha256:<发布摘要>
PLATFORM_UI_IMAGE=ghcr.io/coomia-ai/coomia-platform-ui@sha256:<发布摘要>
FLINK_LOCAL_IMAGE=ghcr.io/coomia-ai/coomia-flink-local@sha256:<发布摘要>
```

当前 `trial.7` 的四个一方镜像摘要见
[`releases/2026.09.30-trial.7/application-images.env`](../releases/2026.09.30-trial.7/application-images.env)。
完整基础设施镜像摘要见
[`releases/2026.09.30-trial.7/infrastructure-images.env`](../releases/2026.09.30-trial.7/infrastructure-images.env)。
两个文件共同构成当前候选包的镜像目录，仍须经过最终发布批准。

```text
<镜像仓库>/<镜像名称>@sha256:<64 位小写十六进制摘要>
```

安装器拒绝 tag、空值和非摘要格式。

## 数据库与基础设施凭据

`POSTGRES_USER` 和 `POSTGRES_DB` 只能使用字母、数字和下划线。`DATABASE_URL` 必须与 PostgreSQL 配置一致。`OBJECT_STORAGE_ACCESS_KEY` 和 `OBJECT_STORAGE_SECRET_KEY` 是 RustFS 使用的 S3 兼容凭据；应用内部仍映射为 `MINIO_*` 变量以保持 SDK 兼容。Doris 当前要求 `DORIS_USER=root`，其密码不得少于 12 个字符。Kubernetes 安装器要求 `mds-app/platform-api-secret.DORIS_PASSWORD` 与 `data-infra/doris-root-secret.password` 完全一致；Compose 安装器会在启动后使用 API 容器中的实际凭据执行真实 Doris 登录。其他密码由 `init-config.sh` 自动生成。

UI 镜像始终通过同源 `/api` 调用后端，并在容器运行时读取 `INTERNAL_API_URL`。Compose 安装器会从 UI 容器请求 `/api/v1/license/status`，代理失败时安装直接失败，不得只依据容器 Ready 状态验收。

## 应用密钥

- `JWT_SECRET`：登录令牌签名密钥。
- `DELIVERY_REPORT_HMAC_SECRET`：交付报告签名密钥，必须与 JWT 密钥不同。
- `MDS_FLINK_CONTROL_TOKEN`：API 与本机 Flink 网关之间的控制令牌。

密钥轮换前必须确认新旧版本兼容，并在维护窗口内完成。不要直接修改运行中容器的环境变量。

## License

- `LICENSE_MODE=online`：API 通过 `LICENSE_SERVER_URL` 校验授权。
- `LICENSE_MODE=offline`：必须设置 `COOMIA_LICENSE_PUBLIC_KEY_FILE`，且只允许使用交付方公钥。

授权操作见 [License 操作](license.md)。

## 客户数据目录

以下路径必须是绝对路径、安装用户所有的独立目录，且不能互相包含：

- `MDS_FLINK_ARTIFACT_DIR`
- `MDS_GENERATED_CONFIG_DIR`
- `MDS_INTAKE_SECRETS_DIR`

安装器会拒绝根目录、系统目录、符号链接和范围过宽的路径。

## 网络与端口

`BIND_ADDRESS` 控制 UI 和 API 监听地址。生产环境应由反向代理或负载均衡器提供 TLS，并限制 API 管理端访问。PostgreSQL、Kafka、Redis、RustFS、Doris 和 TuGraph 默认不映射到主机端口。

`CORS_ORIGINS` 必须设置为实际访问 UI 的受信任源，例如客户正式 HTTPS 域名；多个源的格式应与该版本发布说明一致。不要在生产环境使用通配符。

若 `MDS_DATA_SUBNET` 与客户网络冲突，应在首次安装前同时调整网段、网关及 Doris 固定地址。已投产环境变更网段属于迁移操作。

## 可选管理端口

仅在本机排障时附加 `compose/docker-compose.admin.yml`。该文件将端口绑定到 `127.0.0.1`，不得改为公网地址。排障完成后应停止附加清单。
