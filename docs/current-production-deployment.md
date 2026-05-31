# Current Production Deployment Architecture

本文件记录当前 Magicain 生产部署链路，作为后续排查、扩展和服务拆分时的入口文档。

记录时间：2026-05-29。

## 结论摘要

当前生产部署是“源码仓库构建镜像，`magicain-nginx` 仓库编排并触发 Docker Compose 部署”的模式。

- `cloud` 仓库负责构建并推送后端 `cloud` 镜像。
- `magicain-nginx` 仓库负责把 compose、nginx 配置、环境文件模板和脚本打包上传到 ECS，并执行 `docker compose pull` + `docker compose up -d`。
- 生产运行形态是拆分服务器 Docker Compose，不是 Kubernetes，也不是由 `cloud` 仓库直接登录服务器部署。
- 当前 app-backend compose 只部署单体 `cloud` 后端，没有独立 `ai-server` 服务。

## 仓库职责

### `magicain-bi/cloud`

后端源码仓库。当前镜像 workflow 位于：

- `C:\dev\magicain-bi\cloud\.github\workflows\docker-publish-mono.yml`

触发方式：

- push tag：`v*.*.*`
- 手动 `workflow_dispatch`

主要动作：

1. Checkout 后端代码。
2. 使用 JDK 17。
3. 执行 `mvn clean package -am -pl pangju-server -Dmaven.test.skip=true`。
4. 使用 `pangju-server/Dockerfile` 构建镜像。
5. 推送到阿里云镜像仓库：
   - `crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud`
6. 推送语义化 tag、主次版本 tag 和 `latest`。
7. 分别构建 `linux/amd64`、`linux/arm64`，再合并 manifest。

这个 workflow 只构建和推送镜像，不登录 ECS，不执行 Docker Compose。

### `magicain-nginx`

顶层 DevOps / Harness 仓库。当前生产部署 workflow 位于：

- `.github/workflows/deploy-infra-1.yml`
- `.github/workflows/deploy-infra-2.yml`
- `.github/workflows/deploy-app-backend.yml`
- `.github/workflows/deploy-app-frontend.yml`

触发方式：

- push tag：`v*.*.*`
- 手动 `workflow_dispatch`

主要动作：

1. Checkout `magicain-nginx` 仓库。
2. 打包 `.env*`、`config/`、`docker-compose.*.yml` 和 `scripts/` 为 `deploy-bundle.tar.gz`。
3. 通过 `appleboy/scp-action` 上传到目标 ECS。
4. 通过 `appleboy/ssh-action` 登录目标 ECS。
5. 解压到远端部署目录。
6. 将指定环境文件复制为 `.env`。
7. 注入镜像仓库登录凭据环境变量。
8. 执行 `bash scripts/start-prod.sh <compose-file>`。

`scripts/start-prod.sh` 会：

1. 选择 `.env` 或 `.env.prod`。
2. 执行 `scripts/docker-login.sh`。
3. 创建 `/data/{postgres,postgres-langfuse,redis,elasticsearch,clickhouse,prometheus,grafana}` 等目录。
4. 执行 `docker compose --env-file "$ENV_FILE" -f <compose-file> pull`。
5. 执行 `docker compose --env-file "$ENV_FILE" -f <compose-file> up -d --remove-orphans --force-recreate`。

## 当前服务器/Compose 拆分

服务器与 compose 的对应关系以 `docs/ecs-server-reference.md` 为准。

当前拆分方式：

- `docker-compose.infra-1.yml`
  - PostgreSQL / PgVector
- `docker-compose.infra-2.yml`
  - Elasticsearch
- `docker-compose.app-backend.yml`
  - Redis
  - `cloud`
  - `code-interpreter`
  - `jupyter-kernel`
- `docker-compose.app-frontend.yml`
  - `nginx-proxy`
  - `admin-ui`
  - `agent-ui`
  - `user-ui`

`docker-compose.app-backend.yml` 中的后端主服务是：

- service：`cloud`
- image：`crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:latest`
- profile：`SPRING_PROFILES_ACTIVE=prod`
- port：`48080:48080`

## 当前 Nginx 入口

生产 nginx 配置位于：

- `config/nginx/prod.conf`

生产 frontend compose 通过 `${NGINX_CONFIG_FILE}:/etc/nginx/nginx.conf` 挂载该配置。

当前主要路由：

- `magicain.com` / `www.magicain.com`
  - `/admin/` -> `admin-ui:8080`
  - `/agent/` -> `agent-ui:8081`
  - `/c/` -> `user-ui:8082`
  - `/admin-api/` -> backend upstream
  - `/api/` -> backend upstream
  - `/open/` -> backend upstream
- `openapi.magicain.cn`
  - `/admin-api/` -> backend upstream
  - `/api/` -> backend upstream
  - `/open/` -> backend upstream

当前 backend upstream 指向 app-backend 机器上的单体 cloud：

- `172.27.181.229:48080`

因此，公网 API 入口当前整体进入 `cloud` 单体服务。

## 当前 AI 服务状态

当前生产部署不包含独立 `ai-server`。

现状：

- `magicain-bi/cloud/pom.xml` 中 `pangju-module-ai` 模块被注释。
- `pangju-server/pom.xml` 中 `pangju-module-ai-server` 依赖被注释。
- `pangju-server` 对 `/admin-api/ai/**` 有默认禁用提示。
- `docker-compose.app-backend.yml` 没有 `ai-server` service。
- `config/nginx/prod.conf` 没有把 `/admin-api/ai/**` 单独转发到 AI 服务。

代码层面保留了一些独立服务形态：

- `pangju-module-ai-server` 有独立 `AiServerApplication`。
- `pangju-module-ai-server` 有独立 Dockerfile。
- `magicain-bi` 当前 AI 模块默认端口为 `48090`。
- `magicain-platform` 新版 AI 模块默认端口为 `18080`，但 Dockerfile 仍 `EXPOSE 48090`，如复用需要统一端口。
- `pangju-gateway` 中存在 `ai-server` 的历史/框架路由，但当前生产部署没有使用 `pangju-gateway` 作为公网入口。

## 如果后续要支持独立 `ai-server`

推荐纳入现有部署机制，不建议长期手工绕开。

需要新增或调整：

1. 在 AI 源码所在仓库新增单独镜像构建 workflow。
   - 构建 `pangju-module-ai-server.jar`。
   - 推送独立镜像，例如 `magictensor/ai-server:<tag>` 和 `latest`。
2. 在 `magicain-nginx/docker-compose.app-backend.yml` 增加 `ai-server` service。
   - 指定镜像。
   - 指定 `SPRING_PROFILES_ACTIVE=prod` 或独立 profile。
   - 挂载日志目录。
   - 明确端口映射或只在 Docker network 内暴露。
   - 补充必要环境变量。
3. 在 `config/nginx/prod.conf` 增加更具体的 `/admin-api/ai/` location。
   - 该 location 必须优先于通用 `/admin-api/`。
   - 转发到独立 `ai-server`。
4. 如果需要 MCP/SSE，也要单独设计 `/sse`、`/mcp/message` 等入口。
5. 校验 AI 服务依赖：
   - PostgreSQL schema / migration
   - Redis
   - 模型配置
   - Nacos 或本地配置文件
   - 与 `cloud` 之间的 RPC / Feign 调用
6. 明确健康检查、日志路径、回滚方式和镜像 tag 策略。

短期 PoC 可以手工跑独立容器验证启动和 API，但生产化应回到 `magicain-nginx` compose + GitHub Actions CD。

## 操作边界

- 不要把服务器上的临时手工改动当成长期部署状态。
- 生产部署变更应落到 compose、nginx 配置、workflow 或源码镜像构建配置中。
- 不要在文档中写入 SSH 私钥、镜像仓库密码、数据库密码、证书私钥等敏感信息。
- 涉及远程 ECS 的实际操作前，必须确认目标环境、目标 workflow、目标 tag 和回滚路径。
