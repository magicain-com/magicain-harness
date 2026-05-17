-- 更新aibi_dataset表

ALTER TABLE aibi_dataset
    ALTER COLUMN create_time TYPE TIMESTAMP(3) USING create_time,
    ALTER COLUMN update_time TYPE TIMESTAMP(3) USING update_time;

ALTER TABLE aibi_dataset
ALTER COLUMN create_time SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE aibi_dataset
ALTER COLUMN update_time SET DEFAULT CURRENT_TIMESTAMP;

-- 更新ai_file_record表
ALTER TABLE ai_file_record 
ADD COLUMN IF NOT EXISTS trace_id VARCHAR(256);


-- 更新agent_plan_sop表
ALTER TABLE agent_plan_sop
ADD COLUMN IF NOT EXISTS sop_tags VARCHAR(256);


-- Table structure for system_source_identity_mapping
CREATE TABLE system_source_identity_mapping
(
    id                 int8         NOT NULL,
    source_type        varchar(32)  NOT NULL,
    source_user_id     varchar(128) NOT NULL,
    source_user_name   varchar(128) NULL     DEFAULT NULL,
    source_union_id    varchar(128) NULL     DEFAULT NULL,
    source_open_id     varchar(128) NULL     DEFAULT NULL,
    source_tenant_id   varchar(128) NULL     DEFAULT NULL,
    mobile             varchar(32)  NULL     DEFAULT NULL,
    email              varchar(128) NULL     DEFAULT NULL,
    internal_user_id   int8         NOT NULL,
    status             int2         NOT NULL DEFAULT 1,
    last_login_time    timestamp    NULL     DEFAULT NULL,
    last_verified_time timestamp    NULL     DEFAULT NULL,
    ext_json           text         NULL     DEFAULT NULL,
    creator            varchar(64)  NULL     DEFAULT '',
    create_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater            varchar(64)  NULL     DEFAULT '',
    update_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted            int2         NOT NULL DEFAULT 0,
    tenant_id          int8         NOT NULL DEFAULT 0
);

ALTER TABLE system_source_identity_mapping
    ADD CONSTRAINT pk_system_source_identity_mapping PRIMARY KEY (id);

CREATE UNIQUE INDEX uk_tenant_source_user
    ON system_source_identity_mapping (tenant_id, source_type, source_user_id);

CREATE UNIQUE INDEX uk_tenant_source_internal_user
    ON system_source_identity_mapping (tenant_id, source_type, internal_user_id);

CREATE INDEX idx_source_identity_internal_user_id
    ON system_source_identity_mapping (internal_user_id);

CREATE INDEX idx_source_identity_tenant_status
    ON system_source_identity_mapping (tenant_id, status);

COMMENT ON TABLE system_source_identity_mapping IS '来源身份映射表';
COMMENT ON COLUMN system_source_identity_mapping.id IS '编号';
COMMENT ON COLUMN system_source_identity_mapping.tenant_id IS '租户ID';
COMMENT ON COLUMN system_source_identity_mapping.source_type IS '来源类型，如 PLATFORM_INTERNAL / DINGTALK / FEISHU / WECHAT_ENTERPRISE';
COMMENT ON COLUMN system_source_identity_mapping.source_user_id IS '来源侧用户ID（下游权限 userId 实际取值）';
COMMENT ON COLUMN system_source_identity_mapping.source_user_name IS '来源侧用户名称';
COMMENT ON COLUMN system_source_identity_mapping.source_union_id IS '跨应用统一标识';
COMMENT ON COLUMN system_source_identity_mapping.source_open_id IS '单应用登录标识';
COMMENT ON COLUMN system_source_identity_mapping.source_tenant_id IS '来源侧租户标识（预留）';
COMMENT ON COLUMN system_source_identity_mapping.mobile IS '手机号（预留）';
COMMENT ON COLUMN system_source_identity_mapping.email IS '邮箱（预留）';
COMMENT ON COLUMN system_source_identity_mapping.internal_user_id IS '平台内部用户ID';
COMMENT ON COLUMN system_source_identity_mapping.status IS '映射状态，1 启用，0 停用';
COMMENT ON COLUMN system_source_identity_mapping.last_login_time IS '最近登录时间（预留）';
COMMENT ON COLUMN system_source_identity_mapping.last_verified_time IS '最近校验时间';
COMMENT ON COLUMN system_source_identity_mapping.ext_json IS '扩展信息';
COMMENT ON COLUMN system_source_identity_mapping.creator IS '创建者';
COMMENT ON COLUMN system_source_identity_mapping.create_time IS '创建时间';
COMMENT ON COLUMN system_source_identity_mapping.updater IS '更新者';
COMMENT ON COLUMN system_source_identity_mapping.update_time IS '更新时间';
COMMENT ON COLUMN system_source_identity_mapping.deleted IS '是否删除（0 否，1 是）';

-- Sequence structure for system_source_identity_mapping
CREATE SEQUENCE system_source_identity_mapping_seq
    START 1;

COMMENT ON COLUMN agent_plan_sop.sop_tags IS 'sop 的业务标签';

-- LLM 使用事件表（计费账本）
-- 根据 billing-design.md 设计

CREATE TABLE IF NOT EXISTS agent_llm_usage_event (
    id BIGSERIAL PRIMARY KEY,
    event_id VARCHAR(64) NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    user_id VARCHAR(64),
    request_id VARCHAR(64),

    -- 调用标识
    client_name VARCHAR(50),
    provider VARCHAR(50),
    model VARCHAR(100),
    operation VARCHAR(50) DEFAULT 'chat',

    -- Token 统计
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,

    -- 原文存储（早期阶段）
    prompt_text TEXT,
    completion_text TEXT,

    -- 时间与性能
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    latency_ms BIGINT,

    -- 状态
    success BOOLEAN DEFAULT TRUE,
    error_type VARCHAR(100),
    error_message TEXT,

    -- Trace 关联
    trace_id VARCHAR(64),
    span_id VARCHAR(64),

    -- 扩展字段
    app_id BIGINT,
    task_id VARCHAR(64),
    extra_info TEXT,

    -- 审计字段
    creator VARCHAR(64) DEFAULT '',
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater VARCHAR(64) DEFAULT '',
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted SMALLINT NOT NULL DEFAULT 0,

    CONSTRAINT uk_event_id UNIQUE (event_id, deleted)
);

COMMENT ON TABLE agent_llm_usage_event IS 'LLM使用事件表（计费账本）';
COMMENT ON COLUMN agent_llm_usage_event.event_id IS '事件唯一ID';
COMMENT ON COLUMN agent_llm_usage_event.tenant_id IS '租户ID';
COMMENT ON COLUMN agent_llm_usage_event.user_id IS '用户ID';
COMMENT ON COLUMN agent_llm_usage_event.request_id IS '请求ID';
COMMENT ON COLUMN agent_llm_usage_event.client_name IS '客户端名称：default, mcp, summary, finalize';
COMMENT ON COLUMN agent_llm_usage_event.provider IS '服务商：openai, dashscope, deepseek';
COMMENT ON COLUMN agent_llm_usage_event.model IS '模型名称';
COMMENT ON COLUMN agent_llm_usage_event.operation IS '操作类型：chat, embedding';
COMMENT ON COLUMN agent_llm_usage_event.prompt_tokens IS '输入token数';
COMMENT ON COLUMN agent_llm_usage_event.completion_tokens IS '输出token数';
COMMENT ON COLUMN agent_llm_usage_event.total_tokens IS '总token数';
COMMENT ON COLUMN agent_llm_usage_event.prompt_text IS '输入原文（早期阶段存储）';
COMMENT ON COLUMN agent_llm_usage_event.completion_text IS '输出原文（早期阶段存储）';
COMMENT ON COLUMN agent_llm_usage_event.start_time IS '调用开始时间';
COMMENT ON COLUMN agent_llm_usage_event.end_time IS '调用结束时间';
COMMENT ON COLUMN agent_llm_usage_event.latency_ms IS '延迟毫秒数';
COMMENT ON COLUMN agent_llm_usage_event.success IS '是否成功';
COMMENT ON COLUMN agent_llm_usage_event.error_type IS '错误类型';
COMMENT ON COLUMN agent_llm_usage_event.trace_id IS 'OpenTelemetry TraceId';
COMMENT ON COLUMN agent_llm_usage_event.span_id IS 'OpenTelemetry SpanId';
COMMENT ON COLUMN agent_llm_usage_event.app_id IS '应用ID';
COMMENT ON COLUMN agent_llm_usage_event.task_id IS '任务ID';

-- 索引
CREATE INDEX IF NOT EXISTS idx_agent_usage_event_tenant ON agent_llm_usage_event(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agent_usage_event_user ON agent_llm_usage_event(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_agent_usage_event_trace ON agent_llm_usage_event(trace_id);
CREATE INDEX IF NOT EXISTS idx_agent_usage_event_create_time ON agent_llm_usage_event(create_time);
CREATE INDEX IF NOT EXISTS idx_agent_usage_event_model ON agent_llm_usage_event(model);

-- LLM 价格表
-- 1 credit = 0.1 RMB

CREATE TABLE IF NOT EXISTS agent_llm_price_book (
    id BIGSERIAL PRIMARY KEY,

    -- 模型标识
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    operation VARCHAR(50) NOT NULL DEFAULT 'chat',

    -- 价格（单位：RMB / 百万 token）
    input_price DECIMAL(10, 4) NOT NULL DEFAULT 0,
    output_price DECIMAL(10, 4) NOT NULL DEFAULT 0,

    -- 生效时间
    effective_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP,

    -- 状态
    status SMALLINT NOT NULL DEFAULT 1,

    -- 审计字段
    creator VARCHAR(64) DEFAULT '',
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater VARCHAR(64) DEFAULT '',
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted SMALLINT NOT NULL DEFAULT 0,

    CONSTRAINT uk_price_book UNIQUE (provider, model, operation, effective_from, deleted)
);

COMMENT ON TABLE agent_llm_price_book IS 'LLM价格表';
COMMENT ON COLUMN agent_llm_price_book.provider IS '服务商：openai, dashscope, deepseek, zhipu';
COMMENT ON COLUMN agent_llm_price_book.model IS '模型名称';
COMMENT ON COLUMN agent_llm_price_book.operation IS '操作类型：chat, embedding';
COMMENT ON COLUMN agent_llm_price_book.input_price IS '输入价格（RMB/百万token）';
COMMENT ON COLUMN agent_llm_price_book.output_price IS '输出价格（RMB/百万token）';
COMMENT ON COLUMN agent_llm_price_book.effective_from IS '生效开始时间';
COMMENT ON COLUMN agent_llm_price_book.effective_to IS '生效结束时间';
COMMENT ON COLUMN agent_llm_price_book.status IS '状态：1-启用，0-停用';

-- 索引
CREATE INDEX IF NOT EXISTS idx_price_book_provider_model ON agent_llm_price_book(provider, model);
CREATE INDEX IF NOT EXISTS idx_price_book_effective ON agent_llm_price_book(effective_from, effective_to);

-- 初始化常用模型价格（单位：RMB / 百万 token）
-- 数据来源：各厂商官网价格，2024年12月

-- OpenAI
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('openai', 'gpt-4o', 'chat', 17.5, 70),
('openai', 'gpt-4o-mini', 'chat', 1.05, 4.2),
('openai', 'gpt-4-turbo', 'chat', 70, 210),
('openai', 'gpt-3.5-turbo', 'chat', 3.5, 10.5),
('openai', 'o1', 'chat', 105, 420),
('openai', 'o1-mini', 'chat', 21, 84);

-- DeepSeek
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('deepseek', 'deepseek-chat', 'chat', 1, 2),
('deepseek', 'deepseek-reasoner', 'chat', 4, 16);

-- 阿里云 DashScope (通义千问)
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('dashscope', 'qwen-max', 'chat', 20, 60),
('dashscope', 'qwen-plus', 'chat', 0.8, 2),
('dashscope', 'qwen-turbo', 'chat', 0.3, 0.6),
('dashscope', 'qwen-long', 'chat', 0.5, 2),
('dashscope', 'qwq-32b', 'chat', 1, 3);

-- 智谱 GLM
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('zhipu', 'glm-4-plus', 'chat', 50, 50),
('zhipu', 'glm-4', 'chat', 100, 100),
('zhipu', 'glm-4-flash', 'chat', 0.1, 0.1),
('zhipu', 'glm-4-air', 'chat', 1, 1);

-- Anthropic Claude
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('anthropic', 'claude-3-5-sonnet', 'chat', 21, 105),
('anthropic', 'claude-3-opus', 'chat', 105, 525),
('anthropic', 'claude-3-haiku', 'chat', 1.75, 8.75);

-- Moonshot (Kimi)
INSERT INTO agent_llm_price_book (provider, model, operation, input_price, output_price) VALUES
('moonshot', 'moonshot-v1-8k', 'chat', 12, 12),
('moonshot', 'moonshot-v1-32k', 'chat', 24, 24),
('moonshot', 'moonshot-v1-128k', 'chat', 60, 60);


-- 修改 usage_event 表，增加 credits 字段（保留精度，汇总时取整）
ALTER TABLE agent_llm_usage_event ADD COLUMN IF NOT EXISTS credits DECIMAL(12, 4) DEFAULT 0;

COMMENT ON COLUMN agent_llm_usage_event.credits IS '消耗积分（1 credit = 0.1 RMB，保留4位小数）';

-- 创建租户积分汇总视图（汇总时向上取整）
CREATE OR REPLACE VIEW v_tenant_credit_summary AS
SELECT
    tenant_id,
    DATE(create_time) as stat_date,
    CEIL(SUM(credits)) as total_credits,
    SUM(credits) as total_credits_raw,
    SUM(prompt_tokens) as total_prompt_tokens,
    SUM(completion_tokens) as total_completion_tokens,
    SUM(total_tokens) as total_tokens,
    COUNT(*) as call_count
FROM agent_llm_usage_event
WHERE deleted = 0
GROUP BY tenant_id, DATE(create_time);

-- LLM 计费周期表
-- 根据 billing-design.md 设计

CREATE TABLE IF NOT EXISTS agent_llm_billing_cycle (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_points NUMERIC(18,4) NOT NULL DEFAULT 0,
    used_points NUMERIC(18,4) NOT NULL DEFAULT 0,
    reserved_points NUMERIC(18,4) NOT NULL DEFAULT 0,
    remark VARCHAR(255),

    -- 审计字段
    creator VARCHAR(64) DEFAULT '',
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater VARCHAR(64) DEFAULT '',
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted SMALLINT NOT NULL DEFAULT 0
);

COMMENT ON TABLE agent_llm_billing_cycle IS 'LLM计费周期表';
COMMENT ON COLUMN agent_llm_billing_cycle.tenant_id IS '租户ID';
COMMENT ON COLUMN agent_llm_billing_cycle.start_date IS '计费周期开始日期（包含）';
COMMENT ON COLUMN agent_llm_billing_cycle.end_date IS '计费周期结束日期（包含）';
COMMENT ON COLUMN agent_llm_billing_cycle.total_points IS '周期总点数';
COMMENT ON COLUMN agent_llm_billing_cycle.used_points IS '已结算消耗点数';
COMMENT ON COLUMN agent_llm_billing_cycle.reserved_points IS '预占点数';
COMMENT ON COLUMN agent_llm_billing_cycle.remark IS '备注';

-- 已存在环境增量字段
ALTER TABLE agent_llm_billing_cycle
    ADD COLUMN IF NOT EXISTS used_points NUMERIC(18,4) NOT NULL DEFAULT 0;

ALTER TABLE agent_llm_billing_cycle
    ADD COLUMN IF NOT EXISTS reserved_points NUMERIC(18,4) NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_agent_billing_cycle_tenant_date
    ON agent_llm_billing_cycle(tenant_id, start_date, end_date);
