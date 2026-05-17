-- 建表
CREATE TABLE aibi_app (
                          id BIGINT NOT NULL PRIMARY KEY, -- 主键
                          create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                          update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间（触发器维护）
                          creator VARCHAR(64) DEFAULT '', -- 创建者
                          updater VARCHAR(64) DEFAULT '', -- 更新者
                          deleted SMALLINT NOT NULL DEFAULT 0, -- 逻辑删除：0否，1是
                          tenant_id BIGINT, -- 租户ID
                          app_name VARCHAR(128), -- 应用名称
                          app_desc TEXT, -- 应用描述
                          robot_code VARCHAR(120), -- 机器人代码
                          extend_info TEXT, -- 扩展信息
                          ai_type SMALLINT DEFAULT 1, -- AI类型：0：知识，1：数据
                          ai_model_info TEXT, -- AI模型配置信息
                          ai_model_type VARCHAR(100), -- AI模型类型
                          app_default_reply VARCHAR(1024), -- 默认引导回复
                          database_config TEXT, -- 数据源配置
                          table_route_id BIGINT, -- 表路由ID
                          table_route_prompt TEXT -- 表路由提示语
);

-- 索引
CREATE INDEX idx_tenant ON aibi_app (tenant_id, deleted);

-- 表注释
COMMENT ON TABLE aibi_app IS 'BI应用表';

-- 字段注释
COMMENT ON COLUMN aibi_app.id IS '主键ID';
COMMENT ON COLUMN aibi_app.create_time IS '创建时间';
COMMENT ON COLUMN aibi_app.update_time IS '更新时间';
COMMENT ON COLUMN aibi_app.creator IS '创建者';
COMMENT ON COLUMN aibi_app.updater IS '更新者';
COMMENT ON COLUMN aibi_app.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_app.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_app.app_name IS '应用名称';
COMMENT ON COLUMN aibi_app.app_desc IS '应用描述';
COMMENT ON COLUMN aibi_app.robot_code IS '机器人代码';
COMMENT ON COLUMN aibi_app.extend_info IS '扩展信息';
COMMENT ON COLUMN aibi_app.ai_type IS 'AI类型：0：知识，1：数据';
COMMENT ON COLUMN aibi_app.ai_model_info IS 'AI模型配置信息';
COMMENT ON COLUMN aibi_app.ai_model_type IS 'AI模型类型';
COMMENT ON COLUMN aibi_app.app_default_reply IS '默认引导回复';
COMMENT ON COLUMN aibi_app.database_config IS '数据源配置';
COMMENT ON COLUMN aibi_app.table_route_id IS '表路由ID';
COMMENT ON COLUMN aibi_app.table_route_prompt IS '表路由提示语';

DROP SEQUENCE IF EXISTS aibi_app_seq;
CREATE SEQUENCE aibi_app_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_time_aibi_app
    BEFORE UPDATE ON aibi_app
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TABLE aibi_app_config (
                                 id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                 create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                 update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间
                                 creator VARCHAR(64) DEFAULT '' , -- 创建者
                                 updater VARCHAR(64) DEFAULT '' , -- 更新者
                                 deleted SMALLINT NOT NULL DEFAULT 0, -- 逻辑删除：0否，1是
                                 tenant_id BIGINT DEFAULT NULL, -- 租户ID
                                 app_id BIGINT DEFAULT NULL, -- 关联的AppID
                                 action_param VARCHAR(4096) DEFAULT NULL, -- 参数（根据type决定格式：0链接，1 appId）
                                 avatar_url VARCHAR(512) DEFAULT NULL, -- 头像URL
                                 greeting VARCHAR(1024) DEFAULT NULL, -- 欢迎语
                                 recommend_problem_json VARCHAR(4096) DEFAULT NULL, -- 推荐问题列表
                                 support_reasoning BOOLEAN DEFAULT NULL, -- 支持深度思考：TRUE支持，FALSE不支持
                                 is_default_app BOOLEAN DEFAULT NULL, -- 是否默认应用：TRUE是，FALSE否
                                 extend_info VARCHAR(2048) DEFAULT NULL -- 扩展信息
);

-- 表注释
COMMENT ON TABLE aibi_app_config IS 'App配置信息表';

-- 字段注释
COMMENT ON COLUMN aibi_app_config.id IS '主键ID';
COMMENT ON COLUMN aibi_app_config.create_time IS '创建时间';
COMMENT ON COLUMN aibi_app_config.update_time IS '更新时间';
COMMENT ON COLUMN aibi_app_config.creator IS '创建者';
COMMENT ON COLUMN aibi_app_config.updater IS '更新者';
COMMENT ON COLUMN aibi_app_config.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_app_config.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_app_config.app_id IS '关联的AppID';
COMMENT ON COLUMN aibi_app_config.action_param IS '参数（根据type决定格式：0链接，1 appId）';
COMMENT ON COLUMN aibi_app_config.avatar_url IS '头像URL';
COMMENT ON COLUMN aibi_app_config.greeting IS '欢迎语';
COMMENT ON COLUMN aibi_app_config.recommend_problem_json IS '推荐问题列表';
COMMENT ON COLUMN aibi_app_config.support_reasoning IS '支持深度思考：1支持，0不支持';
COMMENT ON COLUMN aibi_app_config.is_default_app IS '是否默认应用：1是，0否';
COMMENT ON COLUMN aibi_app_config.extend_info IS '扩展信息';

DROP SEQUENCE IF EXISTS aibi_app_config_seq;
CREATE SEQUENCE aibi_app_config_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_time_aibi_app_config
    BEFORE UPDATE ON aibi_app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();


CREATE TABLE aibi_app_dataset_relation (
                                           id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                           create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                           update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间（触发器自动更新）
                                           creator VARCHAR(64) DEFAULT '' , -- 创建者
                                           updater VARCHAR(64) DEFAULT '' , -- 更新者
                                           deleted SMALLINT NOT NULL DEFAULT 0, -- 逻辑删除：0否，1是
                                           tenant_id BIGINT, -- 组织ID
                                           app_id BIGINT, -- 应用ID
                                           ds_id BIGINT, -- 数据集ID
                                           is_online SMALLINT, -- 是否线上环境
                                           is_test SMALLINT, -- 是否测试环境
                                           CONSTRAINT idx_tenant_app_ds_rel UNIQUE (tenant_id, id) -- 模拟MySQL里的KEY索引
);
COMMENT ON TABLE aibi_app_dataset_relation IS 'app与dataset的关系表';
COMMENT ON COLUMN aibi_app_dataset_relation.id IS '主键';
COMMENT ON COLUMN aibi_app_dataset_relation.create_time IS '创建时间';
COMMENT ON COLUMN aibi_app_dataset_relation.update_time IS '更新时间';
COMMENT ON COLUMN aibi_app_dataset_relation.creator IS '创建者';
COMMENT ON COLUMN aibi_app_dataset_relation.updater IS '更新者';
COMMENT ON COLUMN aibi_app_dataset_relation.deleted IS '逻辑删除';
COMMENT ON COLUMN aibi_app_dataset_relation.tenant_id IS '组织Id';
COMMENT ON COLUMN aibi_app_dataset_relation.app_id IS '应用Id';
COMMENT ON COLUMN aibi_app_dataset_relation.ds_id IS '数据集Id';
COMMENT ON COLUMN aibi_app_dataset_relation.is_online IS '是否线上环境';
COMMENT ON COLUMN aibi_app_dataset_relation.is_test IS '是否测试环境';

DROP SEQUENCE IF EXISTS aibi_app_dataset_relation_seq;
CREATE SEQUENCE aibi_app_dataset_relation_seq
    START 1;

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_time_aibi_app_dataset_relation
    BEFORE UPDATE ON aibi_app_dataset_relation
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();


CREATE TABLE aibi_dataset_datasource_relation (
                                                  id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间（触发器自动更新）
                                                  creator VARCHAR(64) DEFAULT '', -- 创建者
                                                  updater VARCHAR(64) DEFAULT '', -- 更新者
                                                  deleted SMALLINT NOT NULL DEFAULT 0, -- 逻辑删除：0否，1是
                                                  tenant_id BIGINT, -- 组织Id
                                                  ds_id BIGINT, -- 数据集Id
                                                  datasource_id BIGINT, -- 数据源Id
                                                  is_online SMALLINT, -- 是否线上环境
                                                  is_test SMALLINT -- 是否测试环境
);

-- 索引
CREATE INDEX idx_tenant_ds_datasource_rel ON aibi_dataset_datasource_relation (tenant_id);

-- 表和字段注释
COMMENT ON TABLE aibi_dataset_datasource_relation IS 'dataset与datasource的关系表';
COMMENT ON COLUMN aibi_dataset_datasource_relation.id IS '主键';
COMMENT ON COLUMN aibi_dataset_datasource_relation.create_time IS '创建时间';
COMMENT ON COLUMN aibi_dataset_datasource_relation.update_time IS '更新时间';
COMMENT ON COLUMN aibi_dataset_datasource_relation.creator IS '创建者';
COMMENT ON COLUMN aibi_dataset_datasource_relation.updater IS '更新者';
COMMENT ON COLUMN aibi_dataset_datasource_relation.deleted IS '逻辑删除';
COMMENT ON COLUMN aibi_dataset_datasource_relation.tenant_id IS '组织Id';
COMMENT ON COLUMN aibi_dataset_datasource_relation.ds_id IS '数据集Id';
COMMENT ON COLUMN aibi_dataset_datasource_relation.datasource_id IS '数据源Id';
COMMENT ON COLUMN aibi_dataset_datasource_relation.is_online IS '是否线上环境';
COMMENT ON COLUMN aibi_dataset_datasource_relation.is_test IS '是否测试环境';

DROP SEQUENCE IF EXISTS aibi_dataset_datasource_relation_seq;
CREATE SEQUENCE aibi_dataset_datasource_relation_seq
    START 1;

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_time_aibi_dataset_datasource_relation
    BEFORE UPDATE ON aibi_dataset_datasource_relation
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TABLE aibi_dataset_table_relation (
                                             id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                             create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                             update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间（触发器自动更新）
                                             creator VARCHAR(64) DEFAULT '', -- 创建者
                                             updater VARCHAR(64) DEFAULT '', -- 更新者
                                             deleted SMALLINT NOT NULL DEFAULT 0, -- 是否删除：0否，1是
                                             tenant_id BIGINT NOT NULL, -- 租户ID
                                             dataset_id BIGINT NOT NULL, -- 数据集Id
                                             table_id BIGINT NOT NULL, -- 表ID
                                             is_online SMALLINT, -- 是否线上
                                             is_test SMALLINT, -- 是否测试
                                             extend_info VARCHAR(4096) -- 扩展信息
);

-- 索引
CREATE INDEX idx_dataset_id ON aibi_dataset_table_relation (tenant_id, dataset_id, deleted);
CREATE INDEX idx_table_search ON aibi_dataset_table_relation (tenant_id, dataset_id, table_id);

-- 表注释
COMMENT ON TABLE aibi_dataset_table_relation IS '数据集与数据表的关联关系';

-- 字段注释
COMMENT ON COLUMN aibi_dataset_table_relation.id IS '主键';
COMMENT ON COLUMN aibi_dataset_table_relation.create_time IS '创建时间';
COMMENT ON COLUMN aibi_dataset_table_relation.update_time IS '更新时间';
COMMENT ON COLUMN aibi_dataset_table_relation.creator IS '创建者';
COMMENT ON COLUMN aibi_dataset_table_relation.updater IS '更新者';
COMMENT ON COLUMN aibi_dataset_table_relation.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_dataset_table_relation.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_dataset_table_relation.dataset_id IS '数据集Id';
COMMENT ON COLUMN aibi_dataset_table_relation.table_id IS '表ID';
COMMENT ON COLUMN aibi_dataset_table_relation.is_online IS '是否线上';
COMMENT ON COLUMN aibi_dataset_table_relation.is_test IS '是否测试';
COMMENT ON COLUMN aibi_dataset_table_relation.extend_info IS '扩展信息';

DROP SEQUENCE IF EXISTS aibi_dataset_table_relation_seq;
CREATE SEQUENCE aibi_dataset_table_relation_seq
    START 1;

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_time_aibi_dataset_table_relation
    BEFORE UPDATE ON aibi_dataset_table_relation
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- 创建表
CREATE TABLE aibi_dataset (
                              id BIGINT NOT NULL PRIMARY KEY, -- 主键
                              create_time TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              update_time TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              creator VARCHAR(64) DEFAULT '',
                              updater VARCHAR(64) DEFAULT '',
                              deleted SMALLINT NOT NULL DEFAULT 0,
                              tenant_id BIGINT NOT NULL,
                              dataset_name VARCHAR(1024) NOT NULL,
                              dataset_desc VARCHAR(4096) DEFAULT '0',
                              ai_type SMALLINT NOT NULL DEFAULT 0,
                              extend_info VARCHAR(4096) DEFAULT NULL,
                              datasource_config VARCHAR(2048) DEFAULT NULL
);

-- 创建索引
CREATE INDEX idx_tenant_ds ON aibi_dataset (tenant_id, deleted);

-- 表注释
COMMENT ON TABLE aibi_dataset IS 'ai资源数据集';

-- 列注释
COMMENT ON COLUMN aibi_dataset.id IS '主键';
COMMENT ON COLUMN aibi_dataset.create_time IS '创建时间';
COMMENT ON COLUMN aibi_dataset.update_time IS '更新时间';
COMMENT ON COLUMN aibi_dataset.creator IS '创建者';
COMMENT ON COLUMN aibi_dataset.updater IS '更新者';
COMMENT ON COLUMN aibi_dataset.deleted IS '逻辑删除';
COMMENT ON COLUMN aibi_dataset.tenant_id IS '租户id';
COMMENT ON COLUMN aibi_dataset.dataset_name IS '数据集名称';
COMMENT ON COLUMN aibi_dataset.dataset_desc IS '数据集的描述信息，对该数据集的内容进行简要描述';
COMMENT ON COLUMN aibi_dataset.ai_type IS 'ai类型，0:chatBI,1:chatMemo,2:chatForm';
COMMENT ON COLUMN aibi_dataset.extend_info IS '扩展属性';
COMMENT ON COLUMN aibi_dataset.datasource_config IS '数据源配置';

DROP SEQUENCE IF EXISTS aibi_dataset_seq;
CREATE SEQUENCE aibi_dataset_seq
    START 1;

-- 创建触发函数，用于自动更新 update_time
CREATE OR REPLACE FUNCTION update_time_aibi_dataset()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器，在每次更新表时自动触发
CREATE TRIGGER trg_update_update_time_aibi_dataset
    BEFORE UPDATE ON aibi_dataset
    FOR EACH ROW
    EXECUTE FUNCTION update_time_aibi_dataset();


-- 创建表
CREATE TABLE aibi_datasource (
                                 id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                 create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 creator VARCHAR(64) DEFAULT '',
                                 updater VARCHAR(64) DEFAULT '',
                                 deleted SMALLINT NOT NULL DEFAULT 0,
                                 tenant_id BIGINT DEFAULT NULL,
                                 datasource_type VARCHAR(32) NOT NULL,
                                 datasource_name VARCHAR(255) DEFAULT NULL,
                                 db_schema VARCHAR(255) DEFAULT NULL,
                                 url VARCHAR(2048) DEFAULT NULL,
                                 user_name VARCHAR(64) DEFAULT NULL,
                                 password VARCHAR(64) DEFAULT NULL,
                                 api_config VARCHAR(2048) DEFAULT NULL,
                                 extend_info VARCHAR(4096) DEFAULT NULL
);

-- 表注释
COMMENT ON TABLE aibi_datasource IS 'AIBI数据源信息';

-- 列注释
COMMENT ON COLUMN aibi_datasource.id IS '主键';
COMMENT ON COLUMN aibi_datasource.create_time IS '创建时间';
COMMENT ON COLUMN aibi_datasource.update_time IS '更新时间';
COMMENT ON COLUMN aibi_datasource.creator IS '创建者';
COMMENT ON COLUMN aibi_datasource.updater IS '更新者';
COMMENT ON COLUMN aibi_datasource.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_datasource.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_datasource.datasource_type IS '数据源类型：mysql,postgresql,hologres,api等';
COMMENT ON COLUMN aibi_datasource.datasource_name IS '数据源名称';
COMMENT ON COLUMN aibi_datasource.db_schema IS 'hologres等的schema';
COMMENT ON COLUMN aibi_datasource.url IS '数据源url';
COMMENT ON COLUMN aibi_datasource.user_name IS '用户名';
COMMENT ON COLUMN aibi_datasource.password IS '密码';
COMMENT ON COLUMN aibi_datasource.api_config IS 'api数据源的配置信息';
COMMENT ON COLUMN aibi_datasource.extend_info IS '扩展信息';

DROP SEQUENCE IF EXISTS aibi_datasource_seq;
CREATE SEQUENCE aibi_datasource_seq
    START 1;

-- 触发器函数：自动更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_datasource()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_datasource
    BEFORE UPDATE ON aibi_datasource
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_datasource();


-- 创建表
CREATE TABLE aibi_intention (
                                id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                creator VARCHAR(64) DEFAULT '',
                                updater VARCHAR(64) DEFAULT '',
                                tenant_id BIGINT NOT NULL,
                                app_id BIGINT NOT NULL,
                                intention_name VARCHAR(128) NOT NULL,
                                intention_desc VARCHAR(1024) DEFAULT NULL,
                                necessary_condition TEXT,
                                extend_info TEXT,
                                deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_intention IS '意图表';

-- 列注释
COMMENT ON COLUMN aibi_intention.id IS '主键';
COMMENT ON COLUMN aibi_intention.create_time IS '创建时间';
COMMENT ON COLUMN aibi_intention.update_time IS '更新时间';
COMMENT ON COLUMN aibi_intention.creator IS '创建者';
COMMENT ON COLUMN aibi_intention.updater IS '更新者';
COMMENT ON COLUMN aibi_intention.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_intention.app_id IS '应用id';
COMMENT ON COLUMN aibi_intention.intention_name IS '意图名字';
COMMENT ON COLUMN aibi_intention.intention_desc IS '意图描述';
COMMENT ON COLUMN aibi_intention.necessary_condition IS '指令中必须包含的条件';
COMMENT ON COLUMN aibi_intention.extend_info IS '扩展字段';
COMMENT ON COLUMN aibi_intention.deleted IS '是否删除';

DROP SEQUENCE IF EXISTS aibi_intention_seq;
CREATE SEQUENCE aibi_intention_seq
    START 1;

-- 触发器函数：自动更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_intention()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_intention
    BEFORE UPDATE ON aibi_intention
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_intention();


-- 创建表
CREATE TABLE aibi_query_logs_detail (
                                        id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                        create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        creator VARCHAR(64) DEFAULT '',
                                        updater VARCHAR(64) DEFAULT '',
                                        deleted SMALLINT NOT NULL DEFAULT 0,
                                        trace_id VARCHAR(256) NOT NULL,
                                        tenant_id BIGINT NOT NULL,
                                        app_id BIGINT NOT NULL,
                                        biz_type VARCHAR(64) DEFAULT NULL,
                                        log_level VARCHAR(64) DEFAULT NULL,
                                        log_type VARCHAR(64) DEFAULT NULL,
                                        log_content TEXT,
                                        llm_type VARCHAR(128) DEFAULT NULL,
                                        query_tokens INTEGER DEFAULT NULL,
                                        completion_tokens INTEGER DEFAULT NULL,
                                        llm_cost INTEGER DEFAULT NULL,
                                        llm_input TEXT,
                                        llm_output TEXT
);

-- 表注释
COMMENT ON TABLE aibi_query_logs_detail IS 'ai问答日志详情记录';

-- 列注释
COMMENT ON COLUMN aibi_query_logs_detail.id IS '主键';
COMMENT ON COLUMN aibi_query_logs_detail.create_time IS '创建时间';
COMMENT ON COLUMN aibi_query_logs_detail.update_time IS '更新时间';
COMMENT ON COLUMN aibi_query_logs_detail.creator IS '创建者';
COMMENT ON COLUMN aibi_query_logs_detail.updater IS '更新者';
COMMENT ON COLUMN aibi_query_logs_detail.deleted IS '是否删除 0否1是';
COMMENT ON COLUMN aibi_query_logs_detail.trace_id IS '与ai_query_logs中一致的traceId';
COMMENT ON COLUMN aibi_query_logs_detail.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_query_logs_detail.app_id IS '应用id';
COMMENT ON COLUMN aibi_query_logs_detail.biz_type IS '业务类型';
COMMENT ON COLUMN aibi_query_logs_detail.log_level IS '日志级别';
COMMENT ON COLUMN aibi_query_logs_detail.log_type IS '日志类型';
COMMENT ON COLUMN aibi_query_logs_detail.log_content IS '日志内容';
COMMENT ON COLUMN aibi_query_logs_detail.llm_type IS '大模型类型';
COMMENT ON COLUMN aibi_query_logs_detail.query_tokens IS '输入消耗的tokens';
COMMENT ON COLUMN aibi_query_logs_detail.completion_tokens IS '输出消耗的tokens';
COMMENT ON COLUMN aibi_query_logs_detail.llm_cost IS '大模型调用耗时';
COMMENT ON COLUMN aibi_query_logs_detail.llm_input IS '大模型输入';
COMMENT ON COLUMN aibi_query_logs_detail.llm_output IS '大模型输出';

DROP SEQUENCE IF EXISTS aibi_query_logs_detail_seq;
CREATE SEQUENCE aibi_query_logs_detail_seq
    START 1;

-- 索引
CREATE INDEX idx_deleted_trace_id_log_type
    ON aibi_query_logs_detail (trace_id, log_type, deleted);

CREATE INDEX idx_tenant_id_deleted_trace_id
    ON aibi_query_logs_detail (tenant_id, trace_id, deleted);

-- 触发器函数：自动更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_query_logs_detail()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_query_logs_detail
    BEFORE UPDATE ON aibi_query_logs_detail
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_query_logs_detail();


-- 创建表
CREATE TABLE aibi_query_logs (
                                 id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                 create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 creator VARCHAR(64) DEFAULT '',
                                 updater VARCHAR(64) DEFAULT '',
                                 deleted SMALLINT NOT NULL DEFAULT 0,
                                 tenant_id BIGINT NOT NULL,
                                 ai_type SMALLINT NOT NULL,
                                 question_sender VARCHAR(200) DEFAULT NULL,
                                 question TEXT NOT NULL,
                                 question_time TIMESTAMP DEFAULT NULL,
                                 question_prompt TEXT,
                                 token INTEGER DEFAULT NULL,
                                 is_debug SMALLINT DEFAULT NULL,
                                 session_type VARCHAR(100) DEFAULT NULL,
                                 session_content VARCHAR(100) DEFAULT NULL,
                                 status INTEGER DEFAULT NULL,
                                 response_sender VARCHAR(200) DEFAULT NULL,
                                 response TEXT,
                                 response_time TIMESTAMP DEFAULT NULL,
                                 feedback_state SMALLINT DEFAULT NULL,
                                 feedback_content VARCHAR(500) DEFAULT NULL,
                                 process_state INTEGER DEFAULT NULL,
                                 process_content VARCHAR(5000) DEFAULT NULL,
                                 process_time TIMESTAMP DEFAULT NULL,
                                 app_id BIGINT DEFAULT NULL,
                                 trace_id VARCHAR(256) DEFAULT NULL,
                                 completed_query TEXT,
                                 query_tokens INTEGER DEFAULT NULL,
                                 completion_tokens INTEGER DEFAULT NULL,
                                 msg_type VARCHAR(64) DEFAULT NULL,
                                 extend_info VARCHAR(4096) DEFAULT NULL,
                                 biz_type VARCHAR(64) DEFAULT NULL,
                                 chain_id BIGINT DEFAULT NULL,
                                 question_sender_type VARCHAR(100) DEFAULT NULL,
                                 question_sender_name VARCHAR(200) DEFAULT NULL
);

-- 表注释
COMMENT ON TABLE aibi_query_logs IS 'ai问答记录表';

-- 列注释
COMMENT ON COLUMN aibi_query_logs.id IS '主键';
COMMENT ON COLUMN aibi_query_logs.create_time IS '创建时间';
COMMENT ON COLUMN aibi_query_logs.update_time IS '更新时间';
COMMENT ON COLUMN aibi_query_logs.creator IS '创建者';
COMMENT ON COLUMN aibi_query_logs.updater IS '更新者';
COMMENT ON COLUMN aibi_query_logs.deleted IS '是否删除';
COMMENT ON COLUMN aibi_query_logs.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_query_logs.ai_type IS '应用类型';
COMMENT ON COLUMN aibi_query_logs.question_sender IS '提问对象';
COMMENT ON COLUMN aibi_query_logs.question IS '问题';
COMMENT ON COLUMN aibi_query_logs.question_time IS '提问时间';
COMMENT ON COLUMN aibi_query_logs.question_prompt IS '问题prompt';
COMMENT ON COLUMN aibi_query_logs.token IS 'token';
COMMENT ON COLUMN aibi_query_logs.is_debug IS '是否调试 0否,1是';
COMMENT ON COLUMN aibi_query_logs.session_type IS '来源类型';
COMMENT ON COLUMN aibi_query_logs.session_content IS '来源信息';
COMMENT ON COLUMN aibi_query_logs.status IS '返回状态';
COMMENT ON COLUMN aibi_query_logs.response_sender IS '响应发送人';
COMMENT ON COLUMN aibi_query_logs.response IS '返回内容';
COMMENT ON COLUMN aibi_query_logs.response_time IS '反馈时间';
COMMENT ON COLUMN aibi_query_logs.feedback_state IS '反馈状态';
COMMENT ON COLUMN aibi_query_logs.feedback_content IS '反馈内容';
COMMENT ON COLUMN aibi_query_logs.process_state IS '处理标记';
COMMENT ON COLUMN aibi_query_logs.process_content IS '处理内容';
COMMENT ON COLUMN aibi_query_logs.process_time IS '处理时间';
COMMENT ON COLUMN aibi_query_logs.app_id IS '应用id';
COMMENT ON COLUMN aibi_query_logs.trace_id IS 'traceId';
COMMENT ON COLUMN aibi_query_logs.completed_query IS '完整意图的问题';
COMMENT ON COLUMN aibi_query_logs.query_tokens IS '大模型输入消耗tokens数量';
COMMENT ON COLUMN aibi_query_logs.completion_tokens IS '大模型输出消耗tokens数量';
COMMENT ON COLUMN aibi_query_logs.msg_type IS '消息类型';
COMMENT ON COLUMN aibi_query_logs.extend_info IS '扩展信息';
COMMENT ON COLUMN aibi_query_logs.biz_type IS '业务类型';
COMMENT ON COLUMN aibi_query_logs.chain_id IS '场景id';
COMMENT ON COLUMN aibi_query_logs.question_sender_type IS '类型';
COMMENT ON COLUMN aibi_query_logs.question_sender_name IS '用户名';

DROP SEQUENCE IF EXISTS aibi_query_logs_seq;
CREATE SEQUENCE aibi_query_logs_seq
    START 1;

-- 索引
CREATE INDEX idx_trace
    ON aibi_query_logs (trace_id, deleted);

CREATE INDEX idx_tenant_log
    ON aibi_query_logs (tenant_id, deleted, id, question_time);

CREATE INDEX idx_app_id_tenant_id
    ON aibi_query_logs (app_id, tenant_id);

CREATE INDEX idx_biz_type_create_time_tenant_id
    ON aibi_query_logs (biz_type, create_time, tenant_id);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_query_logs()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_query_logs
    BEFORE UPDATE ON aibi_query_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_query_logs();


-- 创建表
CREATE TABLE aibi_sample (
                             id BIGINT NOT NULL PRIMARY KEY, -- 主键
                             create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             creator VARCHAR(64) DEFAULT '',
                             updater VARCHAR(64) DEFAULT '',
                             tenant_id BIGINT NOT NULL,
                             app_id BIGINT NOT NULL,
                             sample_query VARCHAR(1000) NOT NULL,
                             sample_answer VARCHAR(5000) NOT NULL,
                             sample_tags VARCHAR(128) DEFAULT NULL,
                             biz_type VARCHAR(64) DEFAULT NULL,
                             extend_info TEXT,
                             deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_sample IS '样例表';

-- 列注释
COMMENT ON COLUMN aibi_sample.id IS '主键';
COMMENT ON COLUMN aibi_sample.create_time IS '创建时间';
COMMENT ON COLUMN aibi_sample.update_time IS '更新时间';
COMMENT ON COLUMN aibi_sample.creator IS '创建者';
COMMENT ON COLUMN aibi_sample.updater IS '更新者';
COMMENT ON COLUMN aibi_sample.tenant_id IS '组织id';
COMMENT ON COLUMN aibi_sample.app_id IS '应用id';
COMMENT ON COLUMN aibi_sample.sample_query IS '样例指令';
COMMENT ON COLUMN aibi_sample.sample_answer IS '样例答案';
COMMENT ON COLUMN aibi_sample.sample_tags IS '样例标签';
COMMENT ON COLUMN aibi_sample.biz_type IS '业务标识';
COMMENT ON COLUMN aibi_sample.extend_info IS '扩展字段';
COMMENT ON COLUMN aibi_sample.deleted IS '是否删除：0否，1是';

DROP SEQUENCE IF EXISTS aibi_sample_seq;
CREATE SEQUENCE aibi_sample_seq
    START 1;

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_sample()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_sample
    BEFORE UPDATE ON aibi_sample
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_sample();


-- 创建表
CREATE TABLE aibi_skill_relation (
                                     id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                     create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     creator VARCHAR(64) DEFAULT '',
                                     updater VARCHAR(64) DEFAULT '',
                                     tenant_id BIGINT NOT NULL,
                                     app_id BIGINT NOT NULL,
                                     skill_id BIGINT NOT NULL,
                                     is_common SMALLINT NOT NULL,
                                     relate_type VARCHAR(64) NOT NULL,
                                     related_id BIGINT NOT NULL,
                                     extend_info TEXT,
                                     deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_skill_relation IS '技能关联表';

-- 列注释
COMMENT ON COLUMN aibi_skill_relation.id IS '主键';
COMMENT ON COLUMN aibi_skill_relation.create_time IS '创建时间';
COMMENT ON COLUMN aibi_skill_relation.update_time IS '更新时间';
COMMENT ON COLUMN aibi_skill_relation.creator IS '创建者';
COMMENT ON COLUMN aibi_skill_relation.updater IS '更新者';
COMMENT ON COLUMN aibi_skill_relation.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_skill_relation.app_id IS '应用id';
COMMENT ON COLUMN aibi_skill_relation.skill_id IS '技能id';
COMMENT ON COLUMN aibi_skill_relation.is_common IS '是否默认召回';
COMMENT ON COLUMN aibi_skill_relation.relate_type IS '关联的类型（资源/知识/样例）';
COMMENT ON COLUMN aibi_skill_relation.related_id IS '关联信息的id';
COMMENT ON COLUMN aibi_skill_relation.extend_info IS '扩展字段';
COMMENT ON COLUMN aibi_skill_relation.deleted IS '是否删除：0否，1是';

DROP SEQUENCE IF EXISTS aibi_skill_relation_seq;
CREATE SEQUENCE aibi_skill_relation_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_app_skill_id
    ON aibi_skill_relation (tenant_id, app_id, skill_id, deleted);

CREATE INDEX idx_tenant_app_skill_id_relate
    ON aibi_skill_relation (tenant_id, app_id, related_id, relate_type, deleted);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_skill_relation()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_skill_relation
    BEFORE UPDATE ON aibi_skill_relation
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_skill_relation();


-- 创建表
CREATE TABLE aibi_skill (
                            id BIGINT NOT NULL PRIMARY KEY, -- 主键
                            create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            creator VARCHAR(64) DEFAULT '',
                            updater VARCHAR(64) DEFAULT '',
                            tenant_id BIGINT NOT NULL,
                            app_id BIGINT NOT NULL,
                            skill_code VARCHAR(64) NOT NULL,
                            skill_key VARCHAR(64) NOT NULL,
                            model VARCHAR(64),
                            parent_skill_id BIGINT,
                            is_enable SMALLINT NOT NULL,
                            custom_prompt TEXT,
                            extend_info TEXT,
                            deleted SMALLINT NOT NULL DEFAULT 0,
                            is_chain SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_skill IS '技能/技能链表';

-- 列注释
COMMENT ON COLUMN aibi_skill.id IS '主键';
COMMENT ON COLUMN aibi_skill.create_time IS '创建时间';
COMMENT ON COLUMN aibi_skill.update_time IS '更新时间';
COMMENT ON COLUMN aibi_skill.creator IS '创建者';
COMMENT ON COLUMN aibi_skill.updater IS '更新者';
COMMENT ON COLUMN aibi_skill.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_skill.app_id IS '应用id';
COMMENT ON COLUMN aibi_skill.skill_code IS '技能类型';
COMMENT ON COLUMN aibi_skill.skill_key IS '技能标识，在技能链中唯一';
COMMENT ON COLUMN aibi_skill.model IS '使用的大模型是什么';
COMMENT ON COLUMN aibi_skill.parent_skill_id IS '技能链id';
COMMENT ON COLUMN aibi_skill.is_enable IS '是否是开启的，默认开启';
COMMENT ON COLUMN aibi_skill.custom_prompt IS '自定义prompt,如果为空则使用模版prompt';
COMMENT ON COLUMN aibi_skill.extend_info IS '扩展字段';
COMMENT ON COLUMN aibi_skill.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_skill.is_chain IS '是否为chain';

DROP SEQUENCE IF EXISTS aibi_skill_seq;
CREATE SEQUENCE aibi_skill_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_app_skill_code
    ON aibi_skill (tenant_id, app_id, skill_code, deleted);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_skill()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_skill
    BEFORE UPDATE ON aibi_skill
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_skill();


-- 创建表
CREATE TABLE aibi_sql_template (
                                   id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                   create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   creator VARCHAR(64) DEFAULT '',
                                   updater VARCHAR(64) DEFAULT '',
                                   name VARCHAR(32) NOT NULL,
                                   content TEXT NOT NULL,
                                   placeholder VARCHAR(256),
                                   placeholder_desc VARCHAR(256),
                                   description VARCHAR(512) NOT NULL,
                                   db_type VARCHAR(32),
                                   tenant_id BIGINT,
                                   app_id BIGINT NOT NULL,
                                   skill_id BIGINT,
                                   deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_sql_template IS 'SQL模板表';

-- 列注释
COMMENT ON COLUMN aibi_sql_template.id IS '主键';
COMMENT ON COLUMN aibi_sql_template.create_time IS '创建时间';
COMMENT ON COLUMN aibi_sql_template.update_time IS '更新时间';
COMMENT ON COLUMN aibi_sql_template.creator IS '创建者';
COMMENT ON COLUMN aibi_sql_template.updater IS '更新者';
COMMENT ON COLUMN aibi_sql_template.name IS '模板名称';
COMMENT ON COLUMN aibi_sql_template.content IS '模板内容';
COMMENT ON COLUMN aibi_sql_template.placeholder IS '占位符';
COMMENT ON COLUMN aibi_sql_template.placeholder_desc IS '占位符描述';
COMMENT ON COLUMN aibi_sql_template.description IS '模板描述';
COMMENT ON COLUMN aibi_sql_template.db_type IS '数据库类型';
COMMENT ON COLUMN aibi_sql_template.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_sql_template.app_id IS '应用id';
COMMENT ON COLUMN aibi_sql_template.skill_id IS '技能id';
COMMENT ON COLUMN aibi_sql_template.deleted IS '是否删除：0否，1是';

DROP SEQUENCE IF EXISTS aibi_sql_template_seq;
CREATE SEQUENCE aibi_sql_template_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_id_app_id_skill_id_db_type_deleted_name
    ON aibi_sql_template (tenant_id, app_id, skill_id, db_type, deleted, name);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_sql_template()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_sql_template
    BEFORE UPDATE ON aibi_sql_template
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_sql_template();


-- 创建表
CREATE TABLE ai_file_record (
                                id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                tenant_id BIGINT,
                                user_id VARCHAR(32) NOT NULL,
                                file_url VARCHAR(512),
                                status INT NOT NULL DEFAULT 2,
                                create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                creator VARCHAR(64) DEFAULT '',
                                updater VARCHAR(64) DEFAULT '',
                                deleted SMALLINT NOT NULL DEFAULT 0,
                                type INT DEFAULT 0,
                                extend_info VARCHAR(2048)
);

-- 表注释
COMMENT ON TABLE ai_file_record IS '文件任务记录表';

-- 列注释
COMMENT ON COLUMN ai_file_record.id IS '主键id';
COMMENT ON COLUMN ai_file_record.tenant_id IS '租户ID';
COMMENT ON COLUMN ai_file_record.user_id IS '操作用户ID';
COMMENT ON COLUMN ai_file_record.file_url IS '文件URL';
COMMENT ON COLUMN ai_file_record.status IS '1-导出中 2-导出成功 3-导出失败，默认2';
COMMENT ON COLUMN ai_file_record.create_time IS '创建时间';
COMMENT ON COLUMN ai_file_record.update_time IS '更新时间';
COMMENT ON COLUMN ai_file_record.creator IS '创建者';
COMMENT ON COLUMN ai_file_record.updater IS '更新者';
COMMENT ON COLUMN ai_file_record.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN ai_file_record.type IS '类型，可以用来区别多种类型的导出任务';
COMMENT ON COLUMN ai_file_record.extend_info IS '扩展字段';

DROP SEQUENCE IF EXISTS ai_file_record_seq;
CREATE SEQUENCE ai_file_record_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_file ON ai_file_record(tenant_id);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_ai_file_record()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_ai_file_record
    BEFORE UPDATE ON ai_file_record
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_ai_file_record();


-- 创建表
CREATE TABLE aibi_chat_message (
                                   id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                   tenant_id BIGINT NOT NULL,
                                   session_id VARCHAR(64) NOT NULL,
                                   msg_trace_id VARCHAR(64) NOT NULL,
                                   message_type VARCHAR(20) NOT NULL,
                                   sender_id VARCHAR(64) NOT NULL,
                                   receiver_id VARCHAR(64) NOT NULL,
                                   content_type VARCHAR(20) NOT NULL,
                                   content TEXT,
                                   status VARCHAR(20) NOT NULL DEFAULT 'running',
                                   extend_info JSONB DEFAULT NULL,
                                   create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   creator VARCHAR(64) DEFAULT '',
                                   updater VARCHAR(64) DEFAULT '',
                                   deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_chat_message IS 'AI聊天消息表';

-- 列注释
COMMENT ON COLUMN aibi_chat_message.id IS '自增主键ID';
COMMENT ON COLUMN aibi_chat_message.tenant_id IS '租户ID，用于多租户隔离';
COMMENT ON COLUMN aibi_chat_message.session_id IS '所属会话ID，对应chat_session表的主键';
COMMENT ON COLUMN aibi_chat_message.msg_trace_id IS '消息追踪ID，同一个对话的一问一答具有相同trace_id';
COMMENT ON COLUMN aibi_chat_message.message_type IS '消息发送方类型：user（用户）、assistant（AI助手）';
COMMENT ON COLUMN aibi_chat_message.sender_id IS '发送者ID，用户为userid，AI助手为assistantid';
COMMENT ON COLUMN aibi_chat_message.receiver_id IS '接收者ID，用户为userid，AI助手为assistantid';
COMMENT ON COLUMN aibi_chat_message.content_type IS '消息内容类型：text（纯文本）、card（复合卡片）等';
COMMENT ON COLUMN aibi_chat_message.content IS '消息正文内容，支持长文本或JSON格式的卡片结构';
COMMENT ON COLUMN aibi_chat_message.status IS '消息状态：running（处理中）、finish（完成）、error（失败）';
COMMENT ON COLUMN aibi_chat_message.extend_info IS '扩展信息字段，以JSON格式存储额外数据，如模型参数、token数等';
COMMENT ON COLUMN aibi_chat_message.create_time IS '创建时间';
COMMENT ON COLUMN aibi_chat_message.update_time IS '更新时间';
COMMENT ON COLUMN aibi_chat_message.creator IS '创建者';
COMMENT ON COLUMN aibi_chat_message.updater IS '更新者';
COMMENT ON COLUMN aibi_chat_message.deleted IS '是否删除：0-未删除，1-已删除';

DROP SEQUENCE IF EXISTS aibi_chat_message_seq;
CREATE SEQUENCE aibi_chat_message_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_id ON aibi_chat_message(tenant_id);
CREATE INDEX idx_session_id ON aibi_chat_message(session_id);
CREATE INDEX idx_msg_trace_id ON aibi_chat_message(msg_trace_id);
CREATE INDEX idx_status ON aibi_chat_message(status);
CREATE INDEX idx_acm_create_time ON aibi_chat_message(create_time);
CREATE INDEX idx_sender_id ON aibi_chat_message(sender_id);
CREATE INDEX idx_creator ON aibi_chat_message(creator);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_chat_message()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_chat_message
    BEFORE UPDATE ON aibi_chat_message
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_chat_message();


-- 创建表
CREATE TABLE aibi_chat_session (
                                   id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                   tenant_id BIGINT NOT NULL,
                                   session_name VARCHAR(255) NOT NULL,
                                   assistant_id BIGINT NOT NULL,
                                   user_id VARCHAR(64) NOT NULL,
                                   extend_info JSONB DEFAULT NULL,
                                   create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   creator VARCHAR(64) DEFAULT '',
                                   updater VARCHAR(64) DEFAULT '',
                                   deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_chat_session IS '会话表，用户与AI助手的会话主表，记录每个会话的基本信息';

-- 列注释
COMMENT ON COLUMN aibi_chat_session.id IS '自增主键ID';
COMMENT ON COLUMN aibi_chat_session.tenant_id IS '租户ID，用于多租户隔离';
COMMENT ON COLUMN aibi_chat_session.session_name IS '会话名称，用户可见的标题';
COMMENT ON COLUMN aibi_chat_session.assistant_id IS '关联的AI助手ID';
COMMENT ON COLUMN aibi_chat_session.user_id IS '创建该会话的用户ID';
COMMENT ON COLUMN aibi_chat_session.extend_info IS '扩展字段，JSON格式存储额外信息，如会话配置、标签等';
COMMENT ON COLUMN aibi_chat_session.create_time IS '创建时间';
COMMENT ON COLUMN aibi_chat_session.update_time IS '更新时间';
COMMENT ON COLUMN aibi_chat_session.creator IS '创建者';
COMMENT ON COLUMN aibi_chat_session.updater IS '更新者';
COMMENT ON COLUMN aibi_chat_session.deleted IS '软删除标识：0-未删除，1-已删除';

-- 索引
CREATE INDEX idx_tenant_session ON aibi_chat_session(tenant_id);
CREATE INDEX idx_user_id ON aibi_chat_session(user_id);
CREATE INDEX idx_assistant_id ON aibi_chat_session(assistant_id);
CREATE INDEX idx_acs_create_time ON aibi_chat_session(create_time);
CREATE INDEX idx_deleted ON aibi_chat_session(deleted);

DROP SEQUENCE IF EXISTS aibi_chat_session_seq;
CREATE SEQUENCE aibi_chat_session_seq
    START 1;

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_chat_session()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_chat_session
    BEFORE UPDATE ON aibi_chat_session
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_chat_session();


-- 创建表
CREATE TABLE aibi_sql_template_relation (
                                            id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                            create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            creator VARCHAR(64) DEFAULT '',
                                            updater VARCHAR(64) DEFAULT '',
                                            template_id BIGINT NOT NULL,
                                            question VARCHAR(256) NOT NULL,
                                            tenant_id BIGINT,
                                            app_id BIGINT NOT NULL,
                                            skill_id BIGINT,
                                            deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_sql_template_relation IS 'SQL模板关联表';

-- 列注释
COMMENT ON COLUMN aibi_sql_template_relation.id IS '主键';
COMMENT ON COLUMN aibi_sql_template_relation.create_time IS '创建时间';
COMMENT ON COLUMN aibi_sql_template_relation.update_time IS '更新时间';
COMMENT ON COLUMN aibi_sql_template_relation.creator IS '创建者';
COMMENT ON COLUMN aibi_sql_template_relation.updater IS '更新者';
COMMENT ON COLUMN aibi_sql_template_relation.template_id IS 'SQL模板id';
COMMENT ON COLUMN aibi_sql_template_relation.question IS '模板关联的推荐问题';
COMMENT ON COLUMN aibi_sql_template_relation.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_sql_template_relation.app_id IS '应用id';
COMMENT ON COLUMN aibi_sql_template_relation.skill_id IS '技能场景id';
COMMENT ON COLUMN aibi_sql_template_relation.deleted IS '是否删除：0否，1是';

-- 索引
CREATE INDEX idx_tenant_id_app_id_skill_id_template_id_deleted
    ON aibi_sql_template_relation (tenant_id, app_id, skill_id, template_id, deleted);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_sql_template_relation()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_sql_template_relation
    BEFORE UPDATE ON aibi_sql_template_relation
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_sql_template_relation();


-- 创建表
CREATE TABLE aibi_table_columns (
                                    id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    creator VARCHAR(64) DEFAULT '',
                                    updater VARCHAR(64) DEFAULT '',
                                    tenant_id BIGINT,
                                    table_id BIGINT,
                                    column_name_en VARCHAR(200),
                                    column_name_ch VARCHAR(200),
                                    column_type VARCHAR(200),
                                    column_desc VARCHAR(5000),
                                    column_example TEXT,
                                    is_dimension SMALLINT,
                                    field_references VARCHAR(500),
                                    is_virtual SMALLINT DEFAULT 0,
                                    virtual_define VARCHAR(500),
                                    value_correction_enabled SMALLINT,
                                    deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_table_columns IS 'AIBI数据表字段详细结构';

-- 列注释
COMMENT ON COLUMN aibi_table_columns.id IS '主键';
COMMENT ON COLUMN aibi_table_columns.create_time IS '创建时间';
COMMENT ON COLUMN aibi_table_columns.update_time IS '更新时间';
COMMENT ON COLUMN aibi_table_columns.creator IS '创建者';
COMMENT ON COLUMN aibi_table_columns.updater IS '更新者';
COMMENT ON COLUMN aibi_table_columns.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_table_columns.table_id IS '表Id';
COMMENT ON COLUMN aibi_table_columns.column_name_en IS '列英文名';
COMMENT ON COLUMN aibi_table_columns.column_name_ch IS '列中文名';
COMMENT ON COLUMN aibi_table_columns.column_type IS '列类型';
COMMENT ON COLUMN aibi_table_columns.column_desc IS '列描述';
COMMENT ON COLUMN aibi_table_columns.column_example IS '列示例值';
COMMENT ON COLUMN aibi_table_columns.is_dimension IS '是否维度';
COMMENT ON COLUMN aibi_table_columns.field_references IS '维表字段关联事实表字段的信息（JSON格式）';
COMMENT ON COLUMN aibi_table_columns.is_virtual IS '是否是虚拟列：0否，1是';
COMMENT ON COLUMN aibi_table_columns.virtual_define IS '虚拟列定义';
COMMENT ON COLUMN aibi_table_columns.value_correction_enabled IS '是否做值矫正';
COMMENT ON COLUMN aibi_table_columns.deleted IS '是否删除：0否，1是';

DROP SEQUENCE IF EXISTS aibi_table_columns_seq;
CREATE SEQUENCE aibi_table_columns_seq
    START 1;

-- 索引
CREATE INDEX idx_table ON aibi_table_columns (tenant_id, table_id);

-- 触发器函数：更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_table_columns()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_table_columns
    BEFORE UPDATE ON aibi_table_columns
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_table_columns();


-- 创建表
CREATE TABLE aibi_table (
                            id BIGINT NOT NULL PRIMARY KEY, -- 主键
                            create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            creator VARCHAR(64) DEFAULT '',
                            updater VARCHAR(64) DEFAULT '',
                            deleted SMALLINT NOT NULL DEFAULT 0,
                            tenant_id BIGINT,
                            table_name_en VARCHAR(255),
                            table_name_ch VARCHAR(255),
                            datasource_config VARCHAR(255),
                            table_desc VARCHAR(5000),
                            table_schema TEXT,
                            is_dim SMALLINT,
                            extend_info VARCHAR(4096)
);

-- 表注释
COMMENT ON TABLE aibi_table IS 'AIBI数据表信息';

-- 列注释
COMMENT ON COLUMN aibi_table.id IS '主键';
COMMENT ON COLUMN aibi_table.create_time IS '创建时间';
COMMENT ON COLUMN aibi_table.update_time IS '更新时间';
COMMENT ON COLUMN aibi_table.creator IS '创建者';
COMMENT ON COLUMN aibi_table.updater IS '更新者';
COMMENT ON COLUMN aibi_table.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_table.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_table.table_name_en IS '表英文名';
COMMENT ON COLUMN aibi_table.table_name_ch IS '表中文名';
COMMENT ON COLUMN aibi_table.datasource_config IS '数据源配置';
COMMENT ON COLUMN aibi_table.table_desc IS '表的描述';
COMMENT ON COLUMN aibi_table.table_schema IS '表的结构';
COMMENT ON COLUMN aibi_table.is_dim IS '是否是维表，不填就是否';
COMMENT ON COLUMN aibi_table.extend_info IS '扩展信息';

DROP SEQUENCE IF EXISTS aibi_table_seq;
CREATE SEQUENCE aibi_table_seq
    START 1;

-- 触发器函数：更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_table()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_table
    BEFORE UPDATE ON aibi_table
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_table();


-- 创建表
CREATE TABLE aibi_tips (
                           id BIGINT NOT NULL PRIMARY KEY, -- 主键
                           create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                           update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                           creator VARCHAR(64) DEFAULT '',
                           updater VARCHAR(64) DEFAULT '',
                           tenant_id BIGINT NOT NULL,
                           app_id BIGINT NOT NULL,
                           tip_name VARCHAR(128),
                           tip_content VARCHAR(2096) NOT NULL,
                           tip_tags VARCHAR(128),
                           biz_type VARCHAR(64),
                           extend_info TEXT,
                           deleted SMALLINT NOT NULL DEFAULT 0
);

-- 表注释
COMMENT ON TABLE aibi_tips IS '经验知识表';

-- 列注释
COMMENT ON COLUMN aibi_tips.id IS '主键';
COMMENT ON COLUMN aibi_tips.create_time IS '创建时间';
COMMENT ON COLUMN aibi_tips.update_time IS '更新时间';
COMMENT ON COLUMN aibi_tips.creator IS '创建者';
COMMENT ON COLUMN aibi_tips.updater IS '更新者';
COMMENT ON COLUMN aibi_tips.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_tips.app_id IS '应用id';
COMMENT ON COLUMN aibi_tips.tip_name IS '经验名字';
COMMENT ON COLUMN aibi_tips.tip_content IS '经验内容';
COMMENT ON COLUMN aibi_tips.tip_tags IS '经验标签';
COMMENT ON COLUMN aibi_tips.biz_type IS '业务区分标识';
COMMENT ON COLUMN aibi_tips.extend_info IS '扩展字段';
COMMENT ON COLUMN aibi_tips.deleted IS '是否删除：0否，1是';

DROP SEQUENCE IF EXISTS aibi_tips_seq;
CREATE SEQUENCE aibi_tips_seq
    START 1;

-- 触发器函数：更新 update_time
CREATE OR REPLACE FUNCTION update_update_time_aibi_tips()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_tips
    BEFORE UPDATE ON aibi_tips
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_tips();


-- 创建表
CREATE TABLE aibi_value_correction (
                                       id BIGINT NOT NULL PRIMARY KEY, -- 主键
                                       create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                       update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                       creator VARCHAR(64) DEFAULT '',
                                       updater VARCHAR(64) DEFAULT '',
                                       tenant_id BIGINT NOT NULL,
                                       deleted SMALLINT NOT NULL DEFAULT 0,
                                       alias VARCHAR(50),
                                       column_value VARCHAR(50),
                                       related_table_column_id BIGINT NOT NULL,
                                       related_table_id BIGINT NOT NULL,
                                       skill_id BIGINT,
                                       is_column_correction SMALLINT,
                                       similarity DECIMAL(10,2),
                                       extend_info TEXT
);

-- 表注释
COMMENT ON TABLE aibi_value_correction IS 'aibi值矫正';

-- 列注释
COMMENT ON COLUMN aibi_value_correction.id IS '主键';
COMMENT ON COLUMN aibi_value_correction.create_time IS '创建时间';
COMMENT ON COLUMN aibi_value_correction.update_time IS '更新时间';
COMMENT ON COLUMN aibi_value_correction.creator IS '创建者';
COMMENT ON COLUMN aibi_value_correction.updater IS '更新者';
COMMENT ON COLUMN aibi_value_correction.tenant_id IS '组织id';
COMMENT ON COLUMN aibi_value_correction.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN aibi_value_correction.alias IS '别名内容';
COMMENT ON COLUMN aibi_value_correction.column_value IS '表字段内容';
COMMENT ON COLUMN aibi_value_correction.related_table_column_id IS '关联表列id';
COMMENT ON COLUMN aibi_value_correction.related_table_id IS '关联表id';
COMMENT ON COLUMN aibi_value_correction.skill_id IS '对应的skillid';
COMMENT ON COLUMN aibi_value_correction.is_column_correction IS '是否是列自助矫正';
COMMENT ON COLUMN aibi_value_correction.similarity IS '相似度阈值';
COMMENT ON COLUMN aibi_value_correction.extend_info IS '扩展信息';

DROP SEQUENCE IF EXISTS aibi_value_correction_seq;
CREATE SEQUENCE aibi_value_correction_seq
    START 1;

-- 索引
CREATE INDEX idx_tenant_id_skillid_iscolumncorrection
    ON aibi_value_correction (tenant_id, skill_id, is_column_correction);

-- 触发器函数：自动更新时间
CREATE OR REPLACE FUNCTION update_update_time_aibi_value_correction()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器：在更新时自动修改 update_time
CREATE TRIGGER trg_update_update_time_aibi_value_correction
    BEFORE UPDATE ON aibi_value_correction
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_aibi_value_correction();

CREATE TABLE chat_ai_vector (
                                id BIGINT PRIMARY KEY,
                                create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间（触发器维护）
                                creator VARCHAR(64) DEFAULT '', -- 创建者
                                updater VARCHAR(64) DEFAULT '', -- 更新者
                                deleted SMALLINT NOT NULL DEFAULT 0, -- 逻辑删除：0否，1是
                                tenant_id BIGINT NOT NULL,
                                app_id BIGINT NOT NULL,
                                vex_type VARCHAR(255) NOT NULL,
                                vex_id BIGINT NOT NULL,
                                vector VECTOR(1536) NOT NULL -- 向量数据，例如 [0.1, 0.2, 0.3]
);

-- 为表添加注释
COMMENT ON TABLE chat_ai_vector IS '存储向量化数据，关联租户、应用及原始数据源';

-- 为各字段添加注释
COMMENT ON COLUMN chat_ai_vector.id IS '主键，自增或业务生成的唯一标识';
COMMENT ON COLUMN chat_ai_vector.tenant_id IS '组织ID，标识数据所属的组织或租户';
COMMENT ON COLUMN chat_ai_vector.app_id IS '应用ID，标识数据所属的具体应用系统';
COMMENT ON COLUMN chat_ai_vector.vex_type IS '向量化类型，例如：text_embedding、image_feature 等';
COMMENT ON COLUMN chat_ai_vector.vex_id IS '向量来源ID，指向原始数据记录（如文章ID、图片ID等）';
COMMENT ON COLUMN chat_ai_vector.vector IS '向量值，存储实际的向量数组，用于相似性计算或AI推理';


DROP SEQUENCE IF EXISTS chat_ai_vector_seq;
CREATE SEQUENCE chat_ai_vector_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_update_time_chat_ai_vector()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_update_time_chat_ai_vector
    BEFORE UPDATE ON chat_ai_vector
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_chat_ai_vector();


-- Table: agent_plan_sop
-- Description: agent规划sop

CREATE TABLE agent_plan_sop (
                                id              BIGSERIAL PRIMARY KEY, -- 主键
                                create_time     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                update_time     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间 (PostgreSQL 不支持 ON UPDATE CURRENT_TIMESTAMP，需用触发器实现，此处仅设默认值)
                                creator         VARCHAR(64) DEFAULT '', -- 创建者
                                updater         VARCHAR(64) DEFAULT '', -- 更新者
                                deleted         SMALLINT DEFAULT 0, -- 是否删除：0否，1是 (PostgreSQL 常用 SMALLINT 或 BOOLEAN)
                                tenant_id       BIGINT, -- 租户ID
                                agent_id        VARCHAR(64), -- 归属的agent, 确定作用的scope, 可能是agent也可能是子agent
                                sop_name        VARCHAR(64), -- sop的名字
                                sop_desc        VARCHAR(512), -- sop的描述
                                sop_tags        VARCHAR(256), -- sop的业务标签
                                content         TEXT -- sop内容 (PostgreSQL 中 TEXT 没有长度限制，相当于 MySQL 的 LONGTEXT)
);

-- 添加注释
COMMENT ON TABLE agent_plan_sop IS 'agent规划sop';
COMMENT ON COLUMN agent_plan_sop.id IS '主键';
COMMENT ON COLUMN agent_plan_sop.create_time IS '创建时间';
COMMENT ON COLUMN agent_plan_sop.update_time IS '更新时间'; -- 注意：PostgreSQL 不支持列级别的自动更新时间戳，需用触发器
COMMENT ON COLUMN agent_plan_sop.creator IS '创建者';
COMMENT ON COLUMN agent_plan_sop.updater IS '更新者';
COMMENT ON COLUMN agent_plan_sop.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN agent_plan_sop.tenant_id IS '租户ID';
COMMENT ON COLUMN agent_plan_sop.agent_id IS '归属的agent, 确定作用的scope, 可能是agent也可能是子agent';
COMMENT ON COLUMN agent_plan_sop.sop_name IS 'sop的名字';
COMMENT ON COLUMN agent_plan_sop.sop_desc IS 'sop的描述';
COMMENT ON COLUMN agent_plan_sop.sop_tags IS 'sop的业务标签';
COMMENT ON COLUMN agent_plan_sop.content IS 'sop内容';


DROP SEQUENCE IF EXISTS agent_plan_sop_seq;
CREATE SEQUENCE agent_plan_sop_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_update_time_agent_plan_sop()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_update_time_agent_plan_sop
    BEFORE UPDATE ON agent_plan_sop
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_agent_plan_sop();


-- Table: agent_memory_tips
-- Description: 长期记忆之一-调优经验

CREATE TABLE agent_memory_tips (
                                   id              BIGSERIAL PRIMARY KEY, -- 主键 (PostgreSQL 使用 BIGSERIAL 自增)
                                   create_time     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 创建时间
                                   update_time     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 更新时间 (PostgreSQL 不支持 ON UPDATE CURRENT_TIMESTAMP，需用触发器实现，此处仅设默认值)
                                   creator         VARCHAR(64) DEFAULT '', -- 创建者
                                   updater         VARCHAR(64) DEFAULT '', -- 更新者
                                   deleted         SMALLINT DEFAULT 0, -- 是否删除：0否，1是 (PostgreSQL 常用 SMALLINT 或 BOOLEAN)
                                   tenant_id       BIGINT, -- 租户ID
                                   biz_module      VARCHAR(64), -- 业务模块名字, 用于什么, 或者业务上的分类, 比如: 用于表选择、根因分析逻辑
                                   agent_id        VARCHAR(64), -- 归属的agent, 确定作用的scope, 可能是agent也可能是子agent
                                   is_dynamic_recall SMALLINT DEFAULT 1, -- 是否动态召回, 默认是1 (PostgreSQL 常用 SMALLINT 或 BOOLEAN)
                                   content         TEXT NOT NULL, -- 调优经验内容
                                   tag_list        TEXT -- 该条经验的标签列表 - list<string> 的jsonstring - 对内容的补充扩展, 用于更准确的召回, 用于模型召回或者向量召回
);

-- 添加注释
COMMENT ON TABLE agent_memory_tips IS '长期记忆之一-调优经验';
COMMENT ON COLUMN agent_memory_tips.id IS '主键';
COMMENT ON COLUMN agent_memory_tips.create_time IS '创建时间';
COMMENT ON COLUMN agent_memory_tips.update_time IS '更新时间'; -- 注意：PostgreSQL 不支持列级别的自动更新时间戳，需用触发器
COMMENT ON COLUMN agent_memory_tips.creator IS '创建者';
COMMENT ON COLUMN agent_memory_tips.updater IS '更新者';
COMMENT ON COLUMN agent_memory_tips.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN agent_memory_tips.tenant_id IS '租户ID';
COMMENT ON COLUMN agent_memory_tips.biz_module IS '业务模块名字, 用于什么, 或者业务上的分类, 比如: 用于表选择、根因分析逻辑';
COMMENT ON COLUMN agent_memory_tips.agent_id IS '归属的agent, 确定作用的scope, 可能是agent也可能是子agent';
COMMENT ON COLUMN agent_memory_tips.is_dynamic_recall IS '是否动态召回, 默认是1';
COMMENT ON COLUMN agent_memory_tips.content IS '调优经验内容';
COMMENT ON COLUMN agent_memory_tips.tag_list IS '该条经验的标签列表
 - list<string> 的jsonstring
 - 对内容的补充扩展, 用于更准确的召回, 用于模型召回或者向量召回';


DROP SEQUENCE IF EXISTS agent_memory_tips_seq;
CREATE SEQUENCE agent_memory_tips_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_update_time_agent_memory_tips()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_update_time_agent_memory_tips
    BEFORE UPDATE ON agent_memory_tips
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_agent_memory_tips();


CREATE TABLE ai_llm_model_config (
                                     id BIGSERIAL PRIMARY KEY,
                                     create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     creator VARCHAR(64) DEFAULT '',
                                     updater VARCHAR(64) DEFAULT '',
                                     deleted SMALLINT DEFAULT 0,               -- 是否删除：0否，1是
                                     tenant_id BIGINT,
                                     model_id VARCHAR(64) NOT NULL UNIQUE,
                                     model_name VARCHAR(128) NOT NULL,
                                     provider VARCHAR(64) NOT NULL,
                                     api_key VARCHAR(512) NOT NULL,
                                     base_url VARCHAR(512),
                                     model_type VARCHAR(32) NOT NULL DEFAULT 'chat',
                                     temperature NUMERIC(3,2) DEFAULT 0.70,
                                     max_tokens INT,
                                     remark VARCHAR(255),
                                     model_config TEXT,
                                     extend_info TEXT,
                                     is_global SMALLINT,                       -- 是否全局
                                     app_id BIGINT,
                                     CONSTRAINT idx_tenant_app_id UNIQUE (tenant_id, app_id, id)
);

-- 字段注释
COMMENT ON TABLE ai_llm_model_config IS '外部大模型接入配置表';
COMMENT ON COLUMN ai_llm_model_config.id IS '主键';
COMMENT ON COLUMN ai_llm_model_config.create_time IS '创建时间';
COMMENT ON COLUMN ai_llm_model_config.update_time IS '更新时间';
COMMENT ON COLUMN ai_llm_model_config.creator IS '创建者';
COMMENT ON COLUMN ai_llm_model_config.updater IS '更新者';
COMMENT ON COLUMN ai_llm_model_config.deleted IS '是否删除：0否，1是';
COMMENT ON COLUMN ai_llm_model_config.tenant_id IS '租户ID';
COMMENT ON COLUMN ai_llm_model_config.model_id IS '模型标识，如 openai-gpt-4o、deepseek-chat、zhipu-glm-4';
COMMENT ON COLUMN ai_llm_model_config.model_name IS '模型名称，如 GPT-4o、DeepSeek-V2、GLM-4';
COMMENT ON COLUMN ai_llm_model_config.provider IS '供应商：openai / deepseek / zhipu / minimax / qwen';
COMMENT ON COLUMN ai_llm_model_config.api_key IS 'API key（建议加密存储）';
COMMENT ON COLUMN ai_llm_model_config.base_url IS '可选：自定义API地址，如代理地址';
COMMENT ON COLUMN ai_llm_model_config.model_type IS '模型类别：chat / image / embedding / audio / tool';
COMMENT ON COLUMN ai_llm_model_config.temperature IS '温度';
COMMENT ON COLUMN ai_llm_model_config.max_tokens IS '生成文本最大长度';
COMMENT ON COLUMN ai_llm_model_config.remark IS '说明备注';
COMMENT ON COLUMN ai_llm_model_config.model_config IS 'model配置, json';
COMMENT ON COLUMN ai_llm_model_config.extend_info IS '扩展字段, json';
COMMENT ON COLUMN ai_llm_model_config.is_global IS '是否是全局的, 否则需要关联到具体skill上';
COMMENT ON COLUMN ai_llm_model_config.app_id IS '归属应用id';

DROP SEQUENCE IF EXISTS ai_llm_model_config_seq;
CREATE SEQUENCE ai_llm_model_config_seq
    START 1;

-- ============================
-- 自动更新时间戳功能
-- ============================
CREATE OR REPLACE FUNCTION update_update_time_ai_llm_model_config()
RETURNS TRIGGER AS $$
BEGIN
   NEW.update_time = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_update_time_ai_llm_model_config
    BEFORE UPDATE ON ai_llm_model_config
    FOR EACH ROW
    EXECUTE FUNCTION update_update_time_ai_llm_model_config();