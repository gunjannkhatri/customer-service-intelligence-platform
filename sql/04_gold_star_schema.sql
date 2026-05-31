-- =============================================
-- FILE: 04_gold_star_schema.sql
-- PURPOSE: Star schema — Power BI reads this
-- =============================================

-- DIMENSION: Agent
CREATE TABLE gold.dim_agent (
    agent_sk            INT IDENTITY(1,1) PRIMARY KEY,
    agent_id            INT             NOT NULL,
    agent_name          VARCHAR(100)    NOT NULL,
    department          VARCHAR(50)     NOT NULL,
    job_role            VARCHAR(50),
    hire_date           DATE,
    tenure_days         INT,
    tenure_band         VARCHAR(20),
    monthly_income      DECIMAL(10,2),
    is_active           BIT,
    effective_from      DATE            DEFAULT GETDATE(),
    is_current          BIT             DEFAULT 1
);
GO

-- DIMENSION: Date
CREATE TABLE gold.dim_date (
    date_sk             INT             PRIMARY KEY,
    full_date           DATE,
    day_of_week         INT,
    day_name            VARCHAR(10),
    is_weekday          BIT,
    week_number         INT,
    month_number        INT,
    month_name          VARCHAR(10),
    quarter_number      INT,
    quarter_label       VARCHAR(10),
    year_number         INT
);
GO

-- DIMENSION: Department
CREATE TABLE gold.dim_department (
    dept_sk             INT IDENTITY(1,1) PRIMARY KEY,
    department_name     VARCHAR(50)     NOT NULL,
    business_unit       VARCHAR(50),
    team_lead           VARCHAR(100),
    sla_target_pct      DECIMAL(5,2)    DEFAULT 90.00,
    headcount_target    INT
);
GO

-- DIMENSION: Priority
CREATE TABLE gold.dim_priority (
    priority_sk         INT IDENTITY(1,1) PRIMARY KEY,
    priority_name       VARCHAR(20),
    sla_hours           INT,
    priority_weight     DECIMAL(3,2)
);
GO

-- Seed dim_priority
INSERT INTO gold.dim_priority (priority_name, sla_hours, priority_weight)
VALUES
    ('Critical', 4,  1.00),
    ('High',     8,  0.75),
    ('Medium',   24, 0.50),
    ('Low',      72, 0.25);
GO

-- FACT: Call Performance
CREATE TABLE gold.fact_call_performance (
    call_perf_sk        BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_sk            INT REFERENCES gold.dim_agent(agent_sk),
    date_sk             INT REFERENCES gold.dim_date(date_sk),
    dept_sk             INT REFERENCES gold.dim_department(dept_sk),
    calls_offered       INT             DEFAULT 0,
    calls_handled       INT             DEFAULT 0,
    calls_abandoned     INT             DEFAULT 0,
    avg_handle_time_sec INT             DEFAULT 0,
    avg_hold_time_sec   INT             DEFAULT 0,
    csat_score          DECIMAL(4,2),
    abandonment_rate    DECIMAL(5,4),
    handle_rate         DECIMAL(5,4),
    loaded_at           DATETIME        DEFAULT GETDATE()
);
GO

-- FACT: Ticket Performance
CREATE TABLE gold.fact_ticket_performance (
    ticket_perf_sk      BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_sk            INT REFERENCES gold.dim_agent(agent_sk),
    date_sk             INT REFERENCES gold.dim_date(date_sk),
    dept_sk             INT REFERENCES gold.dim_department(dept_sk),
    priority_sk         INT REFERENCES gold.dim_priority(priority_sk),
    tickets_assigned    INT             DEFAULT 0,
    tickets_resolved    INT             DEFAULT 0,
    tickets_breached    INT             DEFAULT 0,
    avg_resolution_hrs  DECIMAL(6,2),
    avg_sla_target_hrs  DECIMAL(6,2),
    avg_csat_rating     DECIMAL(3,1),
    sla_compliance_rate DECIMAL(5,4),
    loaded_at           DATETIME        DEFAULT GETDATE()
);
GO

-- FACT: Agent KPI Score (main Power BI source)
CREATE TABLE gold.fact_agent_kpi (
    kpi_sk                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_sk                INT REFERENCES gold.dim_agent(agent_sk),
    date_sk                 INT REFERENCES gold.dim_date(date_sk),
    dept_sk                 INT REFERENCES gold.dim_department(dept_sk),
    call_handle_score       DECIMAL(5,2),
    csat_score_norm         DECIMAL(5,2),
    sla_compliance_score    DECIMAL(5,2),
    ticket_volume_score     DECIMAL(5,2),
    efficiency_score        DECIMAL(5,2),
    agent_performance_score DECIMAL(5,2),
    performance_band        VARCHAR(15),
    rank_in_department      INT,
    rank_overall            INT,
    loaded_at               DATETIME    DEFAULT GETDATE(),
    CONSTRAINT uq_agent_kpi UNIQUE (agent_sk, date_sk)
);
GO

PRINT 'Gold star schema created successfully';