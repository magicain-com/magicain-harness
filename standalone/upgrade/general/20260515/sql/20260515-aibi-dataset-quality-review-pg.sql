-- ChatBI 主题数据集质量评审留档表

CREATE TABLE IF NOT EXISTS aibi_dataset_quality_review (
    id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    dataset_id BIGINT NULL,
    datasource_id BIGINT NOT NULL,
    review_stage VARCHAR(32) NOT NULL DEFAULT 'MANUAL',
    dataset_name VARCHAR(128) NULL,
    table_names_json TEXT NULL,
    table_count INTEGER NOT NULL DEFAULT 0,
    column_count INTEGER NOT NULL DEFAULT 0,
    overall_level VARCHAR(16) NOT NULL DEFAULT 'OK',
    overall_score INTEGER NOT NULL DEFAULT 100,
    has_blocker BOOLEAN NOT NULL DEFAULT FALSE,
    save_action VARCHAR(32) NOT NULL DEFAULT 'ALLOW',
    p0_table_issue_count INTEGER NOT NULL DEFAULT 0,
    top_issue_json TEXT NULL,
    result_json TEXT NULL,
    request_snapshot_json TEXT NULL,
    creator VARCHAR(64) NULL DEFAULT '',
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater VARCHAR(64) NULL DEFAULT '',
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted SMALLINT NOT NULL DEFAULT 0
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pk_aibi_dataset_quality_review'
    ) THEN
        ALTER TABLE aibi_dataset_quality_review
            ADD CONSTRAINT pk_aibi_dataset_quality_review PRIMARY KEY (id);
    END IF;
END $$;

CREATE SEQUENCE IF NOT EXISTS aibi_dataset_quality_review_seq START 1;

CREATE INDEX IF NOT EXISTS idx_aibi_dataset_quality_review_dataset
    ON aibi_dataset_quality_review (tenant_id, dataset_id, id DESC);

CREATE INDEX IF NOT EXISTS idx_aibi_dataset_quality_review_datasource
    ON aibi_dataset_quality_review (tenant_id, datasource_id, id DESC);

COMMENT ON TABLE aibi_dataset_quality_review IS 'ChatBI主题数据集质量评审留档表';
COMMENT ON COLUMN aibi_dataset_quality_review.id IS '主键';
COMMENT ON COLUMN aibi_dataset_quality_review.tenant_id IS '租户ID';
COMMENT ON COLUMN aibi_dataset_quality_review.dataset_id IS '数据集ID，新建草稿评审保存前可为空';
COMMENT ON COLUMN aibi_dataset_quality_review.datasource_id IS '数据源ID';
COMMENT ON COLUMN aibi_dataset_quality_review.review_stage IS '评审阶段：MANUAL/CREATE_SAVE/ADD_TABLE_SAVE/SYNC_SAVE';
COMMENT ON COLUMN aibi_dataset_quality_review.dataset_name IS '评审时的数据集名称';
COMMENT ON COLUMN aibi_dataset_quality_review.table_names_json IS '评审表名列表JSON';
COMMENT ON COLUMN aibi_dataset_quality_review.table_count IS '评审表数量';
COMMENT ON COLUMN aibi_dataset_quality_review.column_count IS '评审字段数量';
COMMENT ON COLUMN aibi_dataset_quality_review.overall_level IS '总体等级：P0/P1/P2/P3/OK';
COMMENT ON COLUMN aibi_dataset_quality_review.overall_score IS '总体评分';
COMMENT ON COLUMN aibi_dataset_quality_review.has_blocker IS '是否存在阻断项';
COMMENT ON COLUMN aibi_dataset_quality_review.save_action IS '保存动作：ALLOW/CONFIRM_REQUIRED/BLOCK';
COMMENT ON COLUMN aibi_dataset_quality_review.p0_table_issue_count IS '数据底表P0问题数量';
COMMENT ON COLUMN aibi_dataset_quality_review.top_issue_json IS '最高优先级问题JSON';
COMMENT ON COLUMN aibi_dataset_quality_review.result_json IS '完整评审结果JSON';
COMMENT ON COLUMN aibi_dataset_quality_review.request_snapshot_json IS '评审请求快照JSON';
