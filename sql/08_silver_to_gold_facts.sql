-- =============================================
-- FILE: 08_silver_to_gold_facts.sql
-- PURPOSE: Load fact tables from Silver
--          fact_call_performance
--          fact_ticket_performance
-- RUN AFTER: 07
-- =============================================


-- ─────────────────────────────────────────
-- FACT 1: fact_call_performance
-- ─────────────────────────────────────────

-- Remove today's data before reload (safe reload)
DELETE FROM gold.fact_call_performance
WHERE date_sk IN (
    SELECT date_sk FROM gold.dim_date
    WHERE full_date = CAST(GETDATE()-1 AS DATE)
);

INSERT INTO gold.fact_call_performance (
    agent_sk,
    date_sk,
    dept_sk,
    calls_offered,
    calls_handled,
    calls_abandoned,
    avg_handle_time_sec,
    avg_hold_time_sec,
    csat_score,
    abandonment_rate,
    handle_rate
)
SELECT
    a.agent_sk,
    d.date_sk,
    dp.dept_sk,
    c.calls_offered,
    c.calls_handled,
    c.calls_abandoned,
    c.avg_handle_time_sec,
    c.avg_hold_time_sec,
    c.csat_score,
    c.abandonment_rate,
    c.handle_rate

FROM silver.call_data c

-- Join to get surrogate keys
JOIN gold.dim_agent a
    ON c.agent_id = a.agent_id
    AND a.is_current = 1

JOIN gold.dim_date d
    ON c.call_date = d.full_date

JOIN silver.employee_data e
    ON c.agent_id = e.employee_id

JOIN gold.dim_department dp
    ON e.department = dp.department_name

WHERE c.is_valid = 1;

PRINT 'fact_call_performance loaded successfully';


-- ─────────────────────────────────────────
-- FACT 2: fact_ticket_performance
-- Aggregated to agent + date + priority level
-- ─────────────────────────────────────────

DELETE FROM gold.fact_ticket_performance
WHERE date_sk IN (
    SELECT date_sk FROM gold.dim_date
    WHERE full_date = CAST(GETDATE()-1 AS DATE)
);

INSERT INTO gold.fact_ticket_performance (
    agent_sk,
    date_sk,
    dept_sk,
    priority_sk,
    tickets_assigned,
    tickets_resolved,
    tickets_breached,
    avg_resolution_hrs,
    avg_sla_target_hrs,
    avg_csat_rating,
    sla_compliance_rate
)
SELECT
    a.agent_sk,
    d.date_sk,
    dp.dept_sk,
    p.priority_sk,

    -- Aggregated measures
    COUNT(t.ticket_id)                              AS tickets_assigned,
    SUM(CASE WHEN t.status = 'RESOLVED'
             THEN 1 ELSE 0 END)                     AS tickets_resolved,
    SUM(CASE WHEN t.is_sla_met = 0
             THEN 1 ELSE 0 END)                     AS tickets_breached,
    ROUND(AVG(t.resolution_time_hrs), 2)            AS avg_resolution_hrs,
    ROUND(AVG(t.sla_target_hrs), 2)                 AS avg_sla_target_hrs,
    ROUND(AVG(t.csat_rating), 2)                    AS avg_csat_rating,
    ROUND(AVG(CAST(t.is_sla_met AS DECIMAL)), 4)    AS sla_compliance_rate

FROM silver.ticket_data t

JOIN gold.dim_agent a
    ON t.agent_id = a.agent_id
    AND a.is_current = 1

JOIN gold.dim_date d
    ON t.ticket_date = d.full_date

JOIN silver.employee_data e
    ON t.agent_id = e.employee_id

JOIN gold.dim_department dp
    ON e.department = dp.department_name

JOIN gold.dim_priority p
    ON UPPER(t.priority) = UPPER(p.priority_name)

WHERE t.is_valid = 1

GROUP BY
    a.agent_sk,
    d.date_sk,
    dp.dept_sk,
    p.priority_sk;

PRINT 'fact_ticket_performance loaded successfully';