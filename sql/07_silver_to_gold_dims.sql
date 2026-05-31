-- =============================================
-- FILE: 07_silver_to_gold_dims.sql
-- PURPOSE: Load all dimension tables
--          dim_agent, dim_date, dim_department
-- RUN AFTER: 06
-- =============================================


-- ─────────────────────────────────────────
-- STEP 1: LOAD dim_agent (upsert with MERGE)
-- ─────────────────────────────────────────
MERGE gold.dim_agent AS target
USING (
    SELECT
        e.employee_id,
        e.employee_name,
        e.department,
        e.job_role,
        e.hire_date,
        e.tenure_days,
        e.monthly_income,
        e.is_active,
        CASE
            WHEN e.tenure_days < 365  THEN '<1yr'
            WHEN e.tenure_days < 1095 THEN '1-3yr'
            WHEN e.tenure_days < 1825 THEN '3-5yr'
            ELSE '5+yr'
        END AS tenure_band
    FROM silver.employee_data e
) AS source
ON target.agent_id   = source.employee_id
AND target.is_current = 1

WHEN MATCHED THEN
    UPDATE SET
        agent_name     = source.employee_name,
        department     = source.department,
        job_role       = source.job_role,
        tenure_days    = source.tenure_days,
        tenure_band    = source.tenure_band,
        monthly_income = source.monthly_income,
        is_active      = source.is_active

WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        agent_id,
        agent_name,
        department,
        job_role,
        hire_date,
        tenure_days,
        tenure_band,
        monthly_income,
        is_active
    )
    VALUES (
        source.employee_id,
        source.employee_name,
        source.department,
        source.job_role,
        source.hire_date,
        source.tenure_days,
        source.tenure_band,
        source.monthly_income,
        source.is_active
    );

PRINT 'dim_agent loaded successfully';


-- ─────────────────────────────────────────
-- STEP 2: LOAD dim_department
-- ─────────────────────────────────────────
MERGE gold.dim_department AS target
USING (
    SELECT DISTINCT
        department          AS department_name,
        'Customer Service'  AS business_unit,
        90.00               AS sla_target_pct
    FROM silver.employee_data
    WHERE department IS NOT NULL
) AS source
ON target.department_name = source.department_name

WHEN MATCHED THEN
    UPDATE SET
        business_unit  = source.business_unit,
        sla_target_pct = source.sla_target_pct

WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        department_name,
        business_unit,
        sla_target_pct
    )
    VALUES (
        source.department_name,
        source.business_unit,
        source.sla_target_pct
    );

PRINT 'dim_department loaded successfully';


-- ─────────────────────────────────────────
-- STEP 3: LOAD dim_date
-- Generates full calendar for 2024
-- ─────────────────────────────────────────

-- Only run if dates not already loaded
IF NOT EXISTS (
    SELECT 1 FROM gold.dim_date
    WHERE year_number = 2024
)
BEGIN

    DECLARE @start_date DATE = '2024-01-01';
    DECLARE @end_date   DATE = '2024-12-31';
    DECLARE @current    DATE = @start_date;

    WHILE @current <= @end_date
    BEGIN
        INSERT INTO gold.dim_date (
            date_sk,
            full_date,
            day_of_week,
            day_name,
            is_weekday,
            week_number,
            month_number,
            month_name,
            quarter_number,
            quarter_label,
            year_number
        )
        VALUES (
            -- date_sk as integer YYYYMMDD
            CAST(FORMAT(@current, 'yyyyMMdd') AS INT),
            @current,
            DATEPART(WEEKDAY, @current),
            DATENAME(WEEKDAY, @current),
            CASE WHEN DATEPART(WEEKDAY, @current)
                 IN (1, 7) THEN 0 ELSE 1 END,
            DATEPART(WEEK, @current),
            MONTH(@current),
            DATENAME(MONTH, @current),
            DATEPART(QUARTER, @current),
            'Q' + CAST(DATEPART(QUARTER, @current) AS VARCHAR)
            + ' ' + CAST(YEAR(@current) AS VARCHAR),
            YEAR(@current)
        );

        SET @current = DATEADD(DAY, 1, @current);
    END

    PRINT 'dim_date loaded for 2024';
END
ELSE
    PRINT 'dim_date already exists — skipped';