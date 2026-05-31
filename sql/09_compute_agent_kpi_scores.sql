-- =============================================
-- FILE: 09_compute_agent_kpi_scores.sql
-- PURPOSE: Calculate Agent Performance Score
--          and load into fact_agent_kpi
-- RUN AFTER: 08
-- =============================================

-- Remove today's scores before recalculating
DELETE FROM gold.fact_agent_kpi
WHERE date_sk IN (
    SELECT date_sk FROM gold.dim_date
    WHERE full_date = CAST(GETDATE()-1 AS DATE)
);

-- Insert new scores
INSERT INTO gold.fact_agent_kpi (
    agent_sk,
    date_sk,
    dept_sk,
    call_handle_score,
    csat_score_norm,
    sla_compliance_score,
    ticket_volume_score,
    efficiency_score,
    agent_performance_score,
    performance_band,
    rank_in_department,
    rank_overall
)

WITH call_scores AS (
    SELECT
        c.agent_sk,
        c.date_sk,
        c.dept_sk,

        -- Score 1: Call Handle Rate (0-100)
        ROUND(
            LEAST(c.handle_rate * 100, 100)
        , 2) AS call_handle_score,

        -- Score 2: CSAT normalized (0-100)
        -- Raw CSAT is 1-5 scale
        ROUND(
            (ISNULL(c.csat_score, 3.0) / 5.0) * 100
        , 2) AS csat_score_norm,

        -- Score 5: Efficiency
        -- Target = 240 seconds (4 minutes)
        ROUND(
            LEAST(
                (240.0 / NULLIF(c.avg_handle_time_sec, 0)) * 100,
                100
            )
        , 2) AS efficiency_score

    FROM gold.fact_call_performance c
    WHERE c.date_sk IN (
        SELECT date_sk FROM gold.dim_date
        WHERE full_date = CAST(GETDATE()-1 AS DATE)
    )
),

ticket_scores AS (
    SELECT
        t.agent_sk,
        t.date_sk,

        -- Score 3: SLA Compliance (0-100)
        ROUND(
            AVG(t.sla_compliance_rate) * 100
        , 2) AS sla_compliance_score,

        -- Score 4: Ticket Volume
        -- Target = 10 tickets per day = 100 score
        ROUND(
            LEAST(
                (CAST(SUM(t.tickets_resolved) AS DECIMAL) / 10.0) * 100,
                100
            )
        , 2) AS ticket_volume_score

    FROM gold.fact_ticket_performance t
    WHERE t.date_sk IN (
        SELECT date_sk FROM gold.dim_date
        WHERE full_date = CAST(GETDATE()-1 AS DATE)
    )
    GROUP BY t.agent_sk, t.date_sk
),

combined AS (
    SELECT
        c.agent_sk,
        c.date_sk,
        c.dept_sk,
        c.call_handle_score,
        c.csat_score_norm,
        ISNULL(t.sla_compliance_score, 50) AS sla_compliance_score,
        ISNULL(t.ticket_volume_score,  50) AS ticket_volume_score,
        c.efficiency_score,

        -- WEIGHTED COMPOSITE SCORE
        -- Weights: Handle 25%, CSAT 25%, SLA 20%, Volume 15%, Efficiency 15%
        ROUND(
            (c.call_handle_score                    * 0.25) +
            (c.csat_score_norm                      * 0.25) +
            (ISNULL(t.sla_compliance_score, 50)     * 0.20) +
            (ISNULL(t.ticket_volume_score,  50)     * 0.15) +
            (c.efficiency_score                     * 0.15)
        , 2) AS agent_performance_score

    FROM call_scores c
    LEFT JOIN ticket_scores t
        ON c.agent_sk = t.agent_sk
        AND c.date_sk = t.date_sk
),

ranked AS (
    SELECT
        *,
        -- Performance band label
        CASE
            WHEN agent_performance_score >= 90 THEN 'STAR'
            WHEN agent_performance_score >= 75 THEN 'HIGH'
            WHEN agent_performance_score >= 60 THEN 'GOOD'
            WHEN agent_performance_score >= 45 THEN 'NEEDS WORK'
            ELSE 'AT RISK'
        END AS performance_band,

        -- Rank within department
        RANK() OVER (
            PARTITION BY dept_sk
            ORDER BY agent_performance_score DESC
        ) AS rank_in_department,

        -- Rank across all agents
        RANK() OVER (
            ORDER BY agent_performance_score DESC
        ) AS rank_overall

    FROM combined
)

SELECT
    agent_sk,
    date_sk,
    dept_sk,
    call_handle_score,
    csat_score_norm,
    sla_compliance_score,
    ticket_volume_score,
    efficiency_score,
    agent_performance_score,
    performance_band,
    rank_in_department,
    rank_overall
FROM ranked;

-- Show final leaderboard
SELECT TOP 10
    a.agent_name,
    dp.department_name,
    k.agent_performance_score,
    k.performance_band,
    k.rank_overall
FROM gold.fact_agent_kpi k
JOIN gold.dim_agent      a  ON k.agent_sk = a.agent_sk
JOIN gold.dim_department dp ON k.dept_sk  = dp.dept_sk
JOIN gold.dim_date       d  ON k.date_sk  = d.date_sk
WHERE d.full_date = CAST(GETDATE()-1 AS DATE)
ORDER BY k.rank_overall ASC;

PRINT 'Agent KPI scores computed successfully';