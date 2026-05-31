-- =============================================
-- FILE: 06_bronze_to_silver_tickets.sql
-- PURPOSE: Clean and validate ticket data
--          from Bronze and load into Silver
-- RUN AFTER: 05
-- =============================================

-- Clear today's silver data before reload
DELETE FROM silver.ticket_data
WHERE loaded_at >= CAST(GETDATE() AS DATE);

-- Insert cleaned data from Bronze to Silver
INSERT INTO silver.ticket_data (
    source_ticket_id,
    agent_id,
    ticket_date,
    priority,
    ticket_type,
    status,
    resolution_time_hrs,
    sla_target_hrs,
    csat_rating,
    is_sla_met,
    sla_breach_hrs,
    is_valid
)
SELECT
    TRIM(ticket_id)                             AS source_ticket_id,
    TRY_CAST(agent_id AS INT)                   AS agent_id,
    TRY_CAST(ticket_date AS DATE)               AS ticket_date,
    UPPER(TRIM(priority))                       AS priority,
    TRIM(ticket_type)                           AS ticket_type,
    UPPER(TRIM(status))                         AS status,
    TRY_CAST(resolution_time_hrs AS DECIMAL(6,2)) AS resolution_time_hrs,
    TRY_CAST(sla_target_hrs AS DECIMAL(6,2))    AS sla_target_hrs,
    TRY_CAST(csat_rating AS DECIMAL(3,1))       AS csat_rating,

    -- SLA met flag: 1 = met, 0 = breached
    CASE
        WHEN TRY_CAST(resolution_time_hrs AS DECIMAL(6,2))
             <= TRY_CAST(sla_target_hrs AS DECIMAL(6,2))
        THEN 1
        ELSE 0
    END AS is_sla_met,

    -- How many hours over SLA (0 if met)
    CASE
        WHEN TRY_CAST(resolution_time_hrs AS DECIMAL(6,2))
             > TRY_CAST(sla_target_hrs AS DECIMAL(6,2))
        THEN TRY_CAST(resolution_time_hrs AS DECIMAL(6,2))
             - TRY_CAST(sla_target_hrs AS DECIMAL(6,2))
        ELSE 0
    END AS sla_breach_hrs,

    -- Validation flag
    CASE
        WHEN TRY_CAST(agent_id AS INT)    IS NULL THEN 0
        WHEN TRY_CAST(ticket_date AS DATE) IS NULL THEN 0
        WHEN TRY_CAST(resolution_time_hrs AS DECIMAL(6,2)) < 0 THEN 0
        ELSE 1
    END AS is_valid

FROM bronze.raw_ticket_data
WHERE loaded_at >= CAST(GETDATE() AS DATE)
  AND TRY_CAST(agent_id    AS INT)  IS NOT NULL
  AND TRY_CAST(ticket_date AS DATE) IS NOT NULL;

-- Show summary
SELECT
    COUNT(*)                                        AS total_records,
    SUM(CASE WHEN is_valid  = 1 THEN 1 ELSE 0 END) AS valid_records,
    SUM(CASE WHEN is_sla_met = 1 THEN 1 ELSE 0 END) AS sla_met,
    SUM(CASE WHEN is_sla_met = 0 THEN 1 ELSE 0 END) AS sla_breached
FROM silver.ticket_data
WHERE loaded_at >= CAST(GETDATE() AS DATE);

PRINT 'Bronze to Silver: Ticket data loaded successfully';