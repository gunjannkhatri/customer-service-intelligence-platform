-- =============================================
-- FILE: 05_bronze_to_silver_calls.sql
-- PURPOSE: Clean and validate call data
--          from Bronze and load into Silver
-- RUN AFTER: 01, 02, 03, 04
-- =============================================

-- Clear today's silver data before reload
DELETE FROM silver.call_data
WHERE loaded_at >= CAST(GETDATE() AS DATE);

-- Insert cleaned data from Bronze to Silver
INSERT INTO silver.call_data (
    agent_id,
    call_date,
    calls_offered,
    calls_handled,
    calls_abandoned,
    avg_handle_time_sec,
    avg_hold_time_sec,
    csat_score,
    abandonment_rate,
    handle_rate,
    is_valid,
    validation_notes
)
SELECT
    -- Cast all fields to correct types
    TRY_CAST(agent_id AS INT),
    TRY_CAST(call_date AS DATE),
    ISNULL(TRY_CAST(calls_offered   AS INT), 0),
    ISNULL(TRY_CAST(calls_handled   AS INT), 0),
    ISNULL(TRY_CAST(calls_abandoned AS INT), 0),
    ISNULL(TRY_CAST(avg_handle_time_sec AS INT), 0),
    ISNULL(TRY_CAST(avg_hold_time_sec   AS INT), 0),
    TRY_CAST(csat_score AS DECIMAL(4,2)),

    -- Calculate abandonment rate
    CASE
        WHEN ISNULL(TRY_CAST(calls_offered AS INT), 0) > 0
        THEN CAST(ISNULL(TRY_CAST(calls_abandoned AS INT), 0) AS DECIMAL)
             / TRY_CAST(calls_offered AS INT)
        ELSE 0
    END AS abandonment_rate,

    -- Calculate handle rate
    CASE
        WHEN ISNULL(TRY_CAST(calls_offered AS INT), 0) > 0
        THEN CAST(ISNULL(TRY_CAST(calls_handled AS INT), 0) AS DECIMAL)
             / TRY_CAST(calls_offered AS INT)
        ELSE 0
    END AS handle_rate,

    -- Validation flag
    CASE
        WHEN TRY_CAST(agent_id AS INT)    IS NULL THEN 0
        WHEN TRY_CAST(call_date AS DATE)  IS NULL THEN 0
        WHEN TRY_CAST(calls_offered AS INT) < 0   THEN 0
        WHEN TRY_CAST(calls_handled AS INT)
             > TRY_CAST(calls_offered AS INT)      THEN 0
        ELSE 1
    END AS is_valid,

    -- Validation notes
    CASE
        WHEN TRY_CAST(agent_id AS INT)    IS NULL THEN 'Invalid agent_id'
        WHEN TRY_CAST(call_date AS DATE)  IS NULL THEN 'Invalid date format'
        WHEN TRY_CAST(calls_offered AS INT) < 0   THEN 'Negative calls_offered'
        WHEN TRY_CAST(calls_handled AS INT)
             > TRY_CAST(calls_offered AS INT)      THEN 'Handled > Offered'
        ELSE 'OK'
    END AS validation_notes

FROM bronze.raw_call_data
WHERE loaded_at >= CAST(GETDATE() AS DATE)
  AND TRY_CAST(agent_id  AS INT)  IS NOT NULL
  AND TRY_CAST(call_date AS DATE) IS NOT NULL;

-- Show summary
SELECT
    COUNT(*)                                    AS total_records,
    SUM(CASE WHEN is_valid = 1 THEN 1 ELSE 0 END) AS valid_records,
    SUM(CASE WHEN is_valid = 0 THEN 1 ELSE 0 END) AS invalid_records
FROM silver.call_data
WHERE loaded_at >= CAST(GETDATE() AS DATE);

PRINT 'Bronze to Silver: Call data loaded successfully';