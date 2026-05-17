# 20260517 Data Agent SOP Scope PG Upgrade

- 升级脚本统一收敛为单文件：`sql/20260517-dataagent-sop-scope-pg.sql`
- 本次变更为 Data Agent 分析思路 SOP 增加可见范围字段：`agent_plan_sop.sop_scope`
- 字段取值约定：
  - `PUBLIC`：公共 SOP，当前 Data Agent 下所有用户可见
  - `PERSONAL`：个人 SOP，仅创建人个人可见
- 对于新装私有化环境，该字段已合并到 `standalone/database/postgresql/3-init.sql`
- 对于已有私有化 PostgreSQL 环境，执行本目录下的升级 SQL
