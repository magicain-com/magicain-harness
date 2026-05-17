# PostgreSQL 数据库脚本说明

## 目录定位

`standalone/database/postgresql` 是私有化部署场景中 PostgreSQL 全量初始化脚本的最终存放位置。
这里的脚本用于：

- 私有化离线交付包中的数据库初始化
- 客户生产环境首次安装时的标准初始化
- 交付视角下的最终数据库脚本归档

需要明确区分：

- `magicain-nginx/standalone/database/postgresql`：交付目录，面向客户部署
- `cloud/sql`：开发目录，面向研发阶段的补丁开发和临时验证

`cloud/sql` 不直接作为客户部署目录使用。

## 当前目录内容

当前目录包含以下初始化脚本：

- `1-base.sql`
- `2-chatbi-permission.sql`
- `2-dataagent-permission.sql`
- `3-init.sql`
- `3-init-update.sql`

这些文件通过 `standalone/docker-compose.yml` 挂载到 PostgreSQL 容器的 `/docker-entrypoint-initdb.d`，用于首次初始化。

## 生效规则

- 首次安装时，如果 `/data/postgres` 为空，PostgreSQL 会执行本目录下的初始化脚本
- 后续升级时，如果 `/data/postgres` 已有数据，初始化脚本不会再次自动执行
- 已部署环境如需升级 schema，必须手动执行增量 SQL

这也是为什么：

- 全量初始化脚本要维护在本目录
- 增量补丁可以先在 `cloud/sql/patch` 开发和验证

## 维护约定

从部署和交付角度，数据库脚本维护遵循以下规则：

1. 新功能或表结构变更，可以先在 `cloud/sql/patch` 编写增量补丁
2. 补丁验证通过后，如需进入私有化全量初始化能力，必须再合并到本目录对应全量脚本中
3. 对客户交付、实施、部署说明时，应以本目录为准，不应直接引用 `cloud/sql` 作为最终交付路径

## 当前外部身份映射改造说明

本次外部身份映射改造已在开发侧补充 PostgreSQL 增量脚本：

- `cloud/sql/patch/20260309-source-identity-mapping-pg.sql`

当前约定如下：

- 对于已存在的生产库/已有系统，仍需要手动执行上述增量 patch
- 对于 `standalone` 私有化全量初始化脚本，本次改造内容已合并到 `3-init-update.sql`

当前状态：

- `20260309-source-identity-mapping-pg.sql` 继续作为存量环境升级脚本
- `3-init-update.sql` 承接新装环境的全量初始化补充

## 当前 LLM 计费改造说明

本次 LLM 计费相关 PostgreSQL 补丁来源于开发侧：

- `cloud/sql/patch/llm-usage-event.sql`
- `cloud/sql/patch/llm-price-book.sql`
- `cloud/sql/patch/llm-billing-cycle.sql`

当前约定如下：

- 对于 `standalone` 私有化全量初始化脚本，上述内容已合并到 `3-init-update.sql`
- 对于已存在的私有化 PostgreSQL 环境，升级包统一执行 `standalone/upgrade/general/20260320/sql/20260320-llm-billing-pg.sql`
- 本次未单独提供“星网”目录版本，统一使用上述通用 PG 升级脚本

## 当前 ChatBI 智能体使用权限改造说明

本次 ChatBI 智能体使用权限 PostgreSQL 表结构参考开发侧：

- `cloud/sql/patch/20260512-aibi-app-access-policy-pg.sql`

当前约定如下：

- 对于 `standalone` 私有化全量初始化脚本，本次内容已合并到 `3-init-update.sql`
- `standalone` 口径为私有化本地化全新部署，仅合并建表、索引、序列和注释
- 历史智能体兼容回填不合并到 `standalone` 初始化脚本；如需处理存量环境，应另行制定明确的升级脚本

## 当前 ChatBI 主题数据集质量评审改造说明

本次 ChatBI 主题数据集质量评审 PostgreSQL 表结构参考开发侧：

- `cloud/sql/patch/20260514-aibi-dataset-quality-review-pg.sql`

当前约定如下：

- 对于 `standalone` 私有化全量初始化脚本，本次内容已合并到 `3-init-update.sql`
- 对于已存在的 PostgreSQL 环境，升级包统一执行 `standalone/upgrade/general/20260515/sql/20260515-aibi-dataset-quality-review-pg.sql`
- 本次只新增质量评审留档表、序列、索引和注释，不需要历史数据回填

## 当前 Data Agent SOP 可见范围改造说明

本次 Data Agent SOP 个性化改造增加 PostgreSQL 字段：

- `agent_plan_sop.sop_scope`

当前约定如下：

- `PUBLIC` 表示公共 SOP，当前 Data Agent 下所有用户可见
- `PERSONAL` 表示个人 SOP，仅创建人个人可见
- 对于 `standalone` 私有化全量初始化脚本，该字段已合并到 `3-init.sql`
- 对于已存在的私有化 PostgreSQL 环境，升级包统一执行 `standalone/upgrade/general/20260517/sql/20260517-dataagent-sop-scope-pg.sql`
