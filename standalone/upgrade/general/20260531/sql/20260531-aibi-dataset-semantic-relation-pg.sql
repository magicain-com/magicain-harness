-- ChatBI dataset semantic relation configuration.
CREATE TABLE IF NOT EXISTS aibi_dataset_semantic_relation (
    id BIGINT NOT NULL,
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creator VARCHAR(64),
    updater VARCHAR(64),
    deleted INTEGER NOT NULL DEFAULT 0,
    tenant_id BIGINT NOT NULL,
    dataset_id BIGINT NOT NULL,
    relation_code VARCHAR(128) NOT NULL,
    relation_name VARCHAR(255),
    main_table_id BIGINT NOT NULL,
    related_table_id BIGINT NOT NULL,
    retain_mode VARCHAR(32) NOT NULL,
    cardinality VARCHAR(32) NOT NULL,
    metric_strategy VARCHAR(32) NOT NULL,
    join_path VARCHAR(32) NOT NULL DEFAULT 'DIRECT',
    business_desc VARCHAR(2048),
    enabled INTEGER NOT NULL DEFAULT 1,
    detection_summary VARCHAR(2048),
    detection_result_json TEXT,
    confirm_source VARCHAR(32) DEFAULT 'MANUAL'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pk_aibi_dataset_semantic_relation'
    ) THEN
        ALTER TABLE aibi_dataset_semantic_relation
            ADD CONSTRAINT pk_aibi_dataset_semantic_relation PRIMARY KEY (id);
    END IF;
END $$;

CREATE SEQUENCE IF NOT EXISTS aibi_dataset_semantic_relation_seq START 1;
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_dataset
    ON aibi_dataset_semantic_relation (tenant_id, dataset_id, deleted);
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_tables
    ON aibi_dataset_semantic_relation (tenant_id, dataset_id, main_table_id, related_table_id, deleted);

CREATE TABLE IF NOT EXISTS aibi_dataset_semantic_relation_field_pair (
    id BIGINT NOT NULL,
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creator VARCHAR(64),
    updater VARCHAR(64),
    deleted INTEGER NOT NULL DEFAULT 0,
    tenant_id BIGINT NOT NULL,
    dataset_id BIGINT NOT NULL,
    relation_id BIGINT NOT NULL,
    main_table_id BIGINT NOT NULL,
    main_column_id BIGINT NOT NULL,
    related_table_id BIGINT NOT NULL,
    related_column_id BIGINT NOT NULL,
    match_type VARCHAR(32) NOT NULL DEFAULT 'EQUAL',
    sort_order INTEGER NOT NULL DEFAULT 0
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pk_aibi_dataset_semantic_relation_field_pair'
    ) THEN
        ALTER TABLE aibi_dataset_semantic_relation_field_pair
            ADD CONSTRAINT pk_aibi_dataset_semantic_relation_field_pair PRIMARY KEY (id);
    END IF;
END $$;

CREATE SEQUENCE IF NOT EXISTS aibi_dataset_semantic_relation_field_pair_seq START 1;
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_pair_relation
    ON aibi_dataset_semantic_relation_field_pair (tenant_id, relation_id, deleted);
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_pair_column
    ON aibi_dataset_semantic_relation_field_pair (tenant_id, dataset_id, main_column_id, related_column_id, deleted);

CREATE TABLE IF NOT EXISTS aibi_dataset_semantic_relation_segment (
    id BIGINT NOT NULL,
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creator VARCHAR(64),
    updater VARCHAR(64),
    deleted INTEGER NOT NULL DEFAULT 0,
    tenant_id BIGINT NOT NULL,
    dataset_id BIGINT NOT NULL,
    relation_id BIGINT NOT NULL,
    segment_type VARCHAR(64),
    segment_config_json TEXT
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pk_aibi_dataset_semantic_relation_segment'
    ) THEN
        ALTER TABLE aibi_dataset_semantic_relation_segment
            ADD CONSTRAINT pk_aibi_dataset_semantic_relation_segment PRIMARY KEY (id);
    END IF;
END $$;

CREATE SEQUENCE IF NOT EXISTS aibi_dataset_semantic_relation_segment_seq START 1;
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_segment_relation
    ON aibi_dataset_semantic_relation_segment (tenant_id, relation_id, deleted);

CREATE TABLE IF NOT EXISTS aibi_dataset_semantic_relation_detection_log (
    id BIGINT NOT NULL,
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creator VARCHAR(64),
    updater VARCHAR(64),
    deleted INTEGER NOT NULL DEFAULT 0,
    tenant_id BIGINT NOT NULL,
    dataset_id BIGINT NOT NULL,
    relation_id BIGINT,
    main_table_id BIGINT NOT NULL,
    related_table_id BIGINT NOT NULL,
    datasource_type VARCHAR(32),
    success INTEGER NOT NULL DEFAULT 0,
    request_json TEXT,
    result_json TEXT,
    error_msg VARCHAR(2048)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pk_aibi_dataset_semantic_relation_detection_log'
    ) THEN
        ALTER TABLE aibi_dataset_semantic_relation_detection_log
            ADD CONSTRAINT pk_aibi_dataset_semantic_relation_detection_log PRIMARY KEY (id);
    END IF;
END $$;

CREATE SEQUENCE IF NOT EXISTS aibi_dataset_semantic_relation_detection_log_seq START 1;
CREATE INDEX IF NOT EXISTS idx_aibi_dataset_semantic_relation_detection_log_dataset
    ON aibi_dataset_semantic_relation_detection_log (tenant_id, dataset_id, id DESC);

COMMENT ON TABLE aibi_dataset_semantic_relation IS 'ChatBI dataset semantic relation configuration';
COMMENT ON TABLE aibi_dataset_semantic_relation_field_pair IS 'ChatBI dataset semantic relation field pairs';
COMMENT ON TABLE aibi_dataset_semantic_relation_segment IS 'ChatBI dataset semantic relation extension segments';
COMMENT ON TABLE aibi_dataset_semantic_relation_detection_log IS 'ChatBI dataset semantic relation detection logs';

-- Compatibility for early installs where deleted was created as BOOLEAN.
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'aibi_dataset_semantic_relation',
        'aibi_dataset_semantic_relation_field_pair',
        'aibi_dataset_semantic_relation_segment',
        'aibi_dataset_semantic_relation_detection_log'
    ]
    LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = tbl
              AND column_name = 'deleted'
              AND data_type = 'boolean'
        ) THEN
            EXECUTE format(
                'ALTER TABLE %I ALTER COLUMN deleted DROP DEFAULT, ALTER COLUMN deleted TYPE INTEGER USING CASE WHEN deleted THEN 1 ELSE 0 END, ALTER COLUMN deleted SET DEFAULT 0',
                tbl
            );
        END IF;
    END LOOP;
END $$;
