-- =============================================
-- FILE: 10_analytical_queries.sql
-- PURPOSE: Useful queries for analysis
--          and Power BI reference
-- =============================================


-- ─────────────────────────────────────────
-- QUERY 1: Full Agent Leaderboard
-- ─────────────────────────────────────────
SELECT
    a.agent_name,
    dp.department_name,
    k.agent_performance_score,
    k.performance_band,
    k.rank_overall,
    k.rank_in_department,
    k.call_handle_score,
    k.csat_score_norm,
    k.sla_compliance_score,
    k.ticket_volume_score,
    k.efficiency_score
FROM gold.fact_agent_kpi k
JOIN gold.dim_agent      a  ON k.agent_sk = a.agent_sk
JOIN gold.dim_department dp ON k.dept_sk  = dp.dept_sk
JOIN gold.dim_date       d  ON k.date_sk  = d.date_sk
WHERE a.is_active = 1
ORDER BY k.rank_overall ASC;


-- ─────────────────────────────────────────
-- QUERY 2: Department SLA Summary
-- ─────────────────────────────────────────
SELECT
    dp.department_name,
    d.month_name,
    d.year_number,
    SUM(t.tickets_assigned)                     AS total_tickets,
    SUM(t.tickets_resolved)                     AS total_resolved,
    SUM(t.tickets_breached)                     AS total_breached,
    ROUND(AVG(t.sla_compliance_rate) * 100, 2)  AS sla_compliance_pct,
    ROUND(AVG(t.avg_resolution_hrs), 2)         AS avg_resolution_hrs,
    ROUND(AVG(t.avg_csat_rating), 2)            AS avg_csat
FROM gold.fact_ticket_performance t
JOIN gold.dim_department dp ON t.dept_sk = dp.dept_sk
JOIN gold.dim_date d        ON t.date_sk = d.date_sk
GROUP BY
    dp.department_name,
    d.month_name,
    d.year_number
ORDER BY
    d.year_number,
    sla_compliance_pct ASC;


-- ─────────────────────────────────────────
-- QUERY 3: Monthly Performance Trend
-- ─────────────────────────────────────────
SELECT
    dp.department_name,
    d.year_number,
    d.month_name,
    d.month_number,
    ROUND(AVG(k.agent_performance_score), 2)    AS avg_score,
    ROUND(AVG(k.csat_score_norm), 2)            AS avg_csat_score,
    ROUND(AVG(k.sla_compliance_score), 2)       AS avg_sla_score,
    COUNT(DISTINCT k.agent_sk)                  AS active_agents,
    SUM(CASE WHEN k.performance_band = 'STAR'
             THEN 1 ELSE 0 END)                 AS star_agents,
    SUM(CASE WHEN k.performance_band = 'AT RISK'
             THEN 1 ELSE 0 END)                 AS at_risk_agents,

    -- Month over month change using LAG
    ROUND(
        AVG(k.agent_performance_score) -
        LAG(AVG(k.agent_performance_score)) OVER (
            PARTITION BY dp.department_name
            ORDER BY d.year_number, d.month_number
        )
    , 2) AS mom_score_change

FROM gold.fact_agent_kpi k
JOIN gold.dim_department dp ON k.dept_sk = dp.dept_sk
JOIN gold.dim_date d        ON k.date_sk = d.date_sk
GROUP BY
    dp.department_name,
    d.year_number,
    d.month_name,
    d.month_number
ORDER BY
    dp.department_name,
    d.year_number,
    d.month_number;


-- ─────────────────────────────────────────
-- QUERY 4: At Risk Agents Alert View
-- ─────────────────────────────────────────
SELECT
    a.agent_name,
    dp.department_name,
    k.agent_performance_score,
    k.sla_compliance_score,
    k.csat_score_norm,
    k.call_handle_score,
    k.performance_band,
    d.full_date
FROM gold.fact_agent_kpi k
JOIN gold.dim_agent      a  ON k.agent_sk = a.agent_sk
JOIN gold.dim_department dp ON k.dept_sk  = dp.dept_sk
JOIN gold.dim_date       d  ON k.date_sk  = d.date_sk
WHERE k.performance_band IN ('AT RISK', 'NEEDS WORK')
  AND a.is_active = 1
ORDER BY
    k.agent_performance_score ASC,
    d.full_date DESC;


-- ─────────────────────────────────────────
-- QUERY 5: Call Performance Summary
-- ─────────────────────────────────────────
SELECT
    dp.department_name,
    d.month_name,
    SUM(c.calls_offered)                        AS total_calls_offered,
    SUM(c.calls_handled)                        AS total_calls_handled,
    SUM(c.calls_abandoned)                      AS total_abandoned,
    ROUND(AVG(c.abandonment_rate) * 100, 2)     AS avg_abandonment_pct,
    ROUND(AVG(c.handle_rate) * 100, 2)          AS avg_handle_rate_pct,
    ROUND(AVG(c.avg_handle_time_sec), 0)        AS avg_handle_time_sec,
    ROUND(AVG(c.csat_score), 2)                 AS avg_csat_score
FROM gold.fact_call_performance c
JOIN gold.dim_department dp ON c.dept_sk = dp.dept_sk
JOIN gold.dim_date d        ON c.date_sk = d.date_sk
GROUP BY
    dp.department_name,
    d.month_name
ORDER BY
    dp.department_name,
    d.month_name;