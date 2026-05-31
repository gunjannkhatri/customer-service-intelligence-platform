-- =============================================
-- FILE: 03_silver_tables.sql
-- PURPOSE: Cleaned and validated tables
--          Types enforced, calculated fields added
-- =============================================

CREATE TABLE silver.call_data (
    call_id             INT IDENTITY(1,1) PRIMARY KEY,
    agent_id            INT             NOT NULL,
    call_date           DATE            NOT NULL,
    calls_offered       INT             NOT NULL DEFAULT 0,
    calls_handled       INT             NOT NULL DEFAULT 0,
    calls_abandoned     INT             NOT NULL DEFAULT 0,
    avg_handle_time_sec INT             NOT NULL DEFAULT 0,
    avg_hold_time_sec   INT             NOT NULL DEFAULT 0,
    csat_score          DECIMAL(4,2),
    abandonment_rate    DECIMAL(5,4),
    handle_rate         DECIMAL(5,4),
    is_valid            BIT             DEFAULT 1,
    validation_notes    VARCHAR(500),
    loaded_at           DATETIME        DEFAULT GETDATE(),
    CONSTRAINT uq_call UNIQUE (agent_id, call_date)
);
GO

CREATE TABLE silver.ticket_data (
    ticket_id           INT IDENTITY(1,1) PRIMARY KEY,
    source_ticket_id    VARCHAR(30),
    agent_id            INT             NOT NULL,
    ticket_date         DATE            NOT NULL,
    priority            VARCHAR(20),
    ticket_type         VARCHAR(50),
    status              VARCHAR(20),
    resolution_time_hrs DECIMAL(6,2),
    sla_target_hrs      DECIMAL(6,2),
    csat_rating         DECIMAL(3,1),
    is_sla_met          BIT,
    sla_breach_hrs      DECIMAL(6,2),
    is_valid            BIT             DEFAULT 1,
    loaded_at           DATETIME        DEFAULT GETDATE()
);
GO

CREATE TABLE silver.employee_data (
    employee_id         INT             PRIMARY KEY,
    employee_name       VARCHAR(100)    NOT NULL,
    department          VARCHAR(50)     NOT NULL,
    job_role            VARCHAR(50),
    hire_date           DATE,
    tenure_days         INT,
    monthly_income      DECIMAL(10,2),
    is_active           BIT             DEFAULT 1,
    loaded_at           DATETIME        DEFAULT GETDATE()
);
GO

PRINT 'Silver tables created successfully';