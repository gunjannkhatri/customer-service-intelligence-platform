-- =============================================
-- FILE: 02_bronze_tables.sql
-- PURPOSE: Raw landing tables — exact copy
--          from source systems. No cleaning.
-- =============================================

-- Raw call data from REST API
CREATE TABLE bronze.raw_call_data (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    agent_id            VARCHAR(20),
    call_date           VARCHAR(20),
    calls_offered       VARCHAR(10),
    calls_handled       VARCHAR(10),
    calls_abandoned     VARCHAR(10),
    avg_handle_time_sec VARCHAR(10),
    avg_hold_time_sec   VARCHAR(10),
    csat_score          VARCHAR(10),
    loaded_at           DATETIME DEFAULT GETDATE(),
    source_file         VARCHAR(200)
);
GO

-- Raw ticket data from REST API
CREATE TABLE bronze.raw_ticket_data (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id           VARCHAR(30),
    agent_id            VARCHAR(20),
    ticket_date         VARCHAR(20),
    priority            VARCHAR(20),
    ticket_type         VARCHAR(50),
    status              VARCHAR(20),
    resolution_time_hrs VARCHAR(10),
    sla_target_hrs      VARCHAR(10),
    csat_rating         VARCHAR(10),
    loaded_at           DATETIME DEFAULT GETDATE(),
    source_file         VARCHAR(200)
);
GO

-- Raw employee data from SQL Server HR system
CREATE TABLE bronze.raw_employee_data (
    raw_id              INT IDENTITY(1,1) PRIMARY KEY,
    employee_id         VARCHAR(20),
    employee_name       VARCHAR(100),
    department          VARCHAR(50),
    job_role            VARCHAR(50),
    hire_date           VARCHAR(20),
    monthly_income      VARCHAR(20),
    is_active           VARCHAR(5),
    loaded_at           DATETIME DEFAULT GETDATE()
);
GO

-- Pipeline audit log
CREATE TABLE config.pipeline_audit (
    audit_id            INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name       VARCHAR(100),
    run_date            DATE,
    status              VARCHAR(20),
    records_loaded      INT,
    error_message       VARCHAR(500),
    duration_sec        INT,
    logged_at           DATETIME DEFAULT GETDATE()
);
GO

-- Watermark table for incremental loading
CREATE TABLE config.pipeline_watermarks (
    pipeline_name       VARCHAR(100) PRIMARY KEY,
    last_successful_run DATETIME2,
    last_run_status     VARCHAR(20),
    records_processed   INT,
    updated_at          DATETIME2 DEFAULT GETUTCDATE()
);
GO

-- Seed watermark table
INSERT INTO config.pipeline_watermarks
    (pipeline_name, last_successful_run, last_run_status)
VALUES
    ('call_api_extract',    '2024-01-01 00:00:00', 'INIT'),
    ('ticket_api_extract',  '2024-01-01 00:00:00', 'INIT'),
    ('employee_extract',    '2024-01-01 00:00:00', 'INIT');
GO

PRINT 'Bronze tables created successfully';