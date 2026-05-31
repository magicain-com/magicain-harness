# Magicain 系统的 Harness Engineering 项目

用于Coding时组织各个repo，同时也用于DevOps

## 各repo介绍

- `magicain-harness`: Harness，顶层repo，包括文档，约定，DevOps脚本和配置。用于串联各repo
- `magicain-cloud`: 后端，Java Spring Boot Spring Cloud 技术栈，通过子Module区分各模块
- `magicain-agent-ui`: Agent管理后台前端，Agent产品的管理端，React技术栈
- `magicain-admin-ui`: Admin管理后台，SaaS产品的管理端，Vue技术栈
- `magicain-ui`: Agent用户前端，Agent产品的用户端，React技术栈

## 开发规范

- Feature开发活Bug fix完毕后要进行至少后端的集成测试和前端的冒烟测试
- 后端集成测试使用bash，脚本保留在后端repo
- 冒烟测试使用playwright cli
- Commit message需要根据开发内容进行总结，格式上采用feat:，bugfix:，chore: 等这些前缀表示不同类型的提交
- 提交PR时要根据这次改动的过程总结决策过程和这次开发的结果并放到PR的message中

## 本地测试规范

- 可以在本地非沙盒环境启动前后端进行测试，包括集成测试，冒烟测试，UI测试
- 中间件依赖云端，包括DB，Redis，ES
- 通过SaaS的租户隔离构建测试环境，方便留存测试数据
- 本地测试是通过 [scripts/start-local.sh](scripts/start-local.sh) 用这个Nginx代理各个服务。统一在 http://localshot:7070/admin/ 登录，用户端 http://localshot:7070/c/?appId=x 来访问某个 appId 的应用
- 本地测试登录租户为"演示"（tenantId=128），用户名是"yanshiadmin"，密码是"123456"

## 参考文档

- System map: [ARCHITECTURE.md](ARCHITECTURE.md)
- Current production deployment: [docs/current-production-deployment.md](docs/current-production-deployment.md)
- Repo map: [docs/references/repo-map.md](docs/references/repo-map.md)
- System docs: [docs/systems/](docs/systems/)
- API/smoke context: [docs/testing/api-smoke-harness.md](docs/testing/api-smoke-harness.md)
- PR readiness: [docs/process/pull-request-readiness.md](docs/process/pull-request-readiness.md)
- Feature plan: [docs/exec-plans/feature-plan-template.md](docs/exec-plans/feature-plan-template.md)
- Release gates: [docs/quality/release-gates.md](docs/quality/release-gates.md)

## 部署架构入口

当问题涉及当前生产部署方式、GitHub Actions CD、Docker Compose 拆分、镜像构建、Nginx 入口路由、ECS 机器职责或独立后端服务扩展时，先阅读：

- `docs/current-production-deployment.md`

该文档记录当前真实部署链路。不要仅凭记忆判断 tag 后会发生什么、哪个仓库负责部署、或生产环境是否已经包含某个独立服务。
