# Azure Data Factory — Pipeline Overview

## Pipeline Architecture


pl_extract_api_data          (6:00 AM daily)
        │
        ▼ on success
pl_transform_bronze_to_gold  (7:00 AM daily)
        │
        ▼ on success
pl_refresh_and_deliver       (8:00 AM daily)
        │
        ▼ always runs
pl_audit_and_monitor         (logs every run)


## Pipeline 1: pl_extract_api_data

*Purpose:* Extract raw data from all 3 sources into Bronze layer  
*Trigger:* Daily Schedule — 6:00 AM UTC  
*Estimated Duration:* 10 to 15 minutes

### Activity 1 — Copy Call Data (HTTP to Azure SQL)

| Setting | Value |
|---|---|
| Type | Copy Activity |
| Source Type | HTTP Linked Service |
| URL | https://raw.githubusercontent.com/gunjankhatri/novacare-data/main/call_data.json |
| Format | JSON |
| Authentication | Anonymous |
| Sink | Azure SQL Database |
| Sink Table | bronze.raw_call_data |
| Write Mode | Insert |

### Activity 2 — Copy Ticket Data (HTTP to Azure SQL)

| Setting | Value |
|---|---|
| Type | Copy Activity |
| Source Type | HTTP Linked Service |
| URL | Your Mockaroo or Kaggle processed file URL |
| Format | CSV |
| Sink Table | bronze.raw_ticket_data |

### Activity 3 — Copy Employee Data (SQL Server to Azure SQL)

| Setting | Value |
|---|---|
| Type | Copy Activity |
| Source Type | SQL Server Linked Service |
| Query | SELECT * FROM hr.employees WHERE modified_date > '@{pipeline().parameters.watermark}' |
| Sink Table | bronze.raw_employee_data |

### Activity 4 — Update Watermark

| Setting | Value |
|---|---|
| Type | Stored Procedure Activity |
| Procedure | config.usp_update_watermark |
| Parameter 1 | pipeline_name = 'employee_extract' |
| Parameter 2 | watermark = @{utcnow()} |

### On Failure Handling

| Setting | Value |
|---|---|
| Type | Web Activity |
| URL | Your Logic App or Power Automate HTTP trigger URL |
| Method | POST |
| Body | {"status": "FAILED", "pipeline": "pl_extract_api_data", "time": "@{utcnow()}"} |

---

## Pipeline 2: pl_transform_bronze_to_gold

*Purpose:* Clean, validate, and load Star Schema  
*Trigger:* On success completion of Pipeline 1  
*Estimated Duration:* 8 to 10 minutes

### Activities — Run in This Exact Order

| Step | Activity Name | Type | What It Does |
|---|---|---|---|
| 1 | bronze_to_silver_calls | Stored Procedure | Cleans call data, casts types, calculates handle rate |
| 2 | bronze_to_silver_tickets | Stored Procedure | Cleans ticket data, calculates SLA breach flag |
| 3 | bronze_to_silver_employees | Stored Procedure | Cleans employee data, calculates tenure |
| 4 | load_dim_date | Stored Procedure | Inserts any new dates into dim_date |
| 5 | load_dim_agent | Stored Procedure | Upserts employee dimension using MERGE |
| 6 | load_dim_department | Stored Procedure | Upserts department dimension |
| 7 | load_fact_call_performance | Stored Procedure | Loads daily call fact table |
| 8 | load_fact_ticket_performance | Stored Procedure | Loads daily ticket fact table |
| 9 | compute_agent_kpi_scores | Stored Procedure | Calculates weighted Agent Performance Score |

### On Any Failure

| Action | Detail |
|---|---|
| Log error | INSERT into config.pipeline_audit with status FAILED |
| Send alert | Web Activity triggers Power Automate email flow |
| Stop pipeline | Remaining activities do not execute |

---

## Pipeline 3: pl_refresh_and_deliver

*Purpose:* Refresh Power BI dataset and trigger automated report delivery  
*Trigger:* On success of Pipeline 2  
*Estimated Duration:* 5 minutes

### Activity 1 — Trigger Power BI Dataset Refresh

| Setting | Value |
|---|---|
| Type | Web Activity |
| URL | https://api.powerbi.com/v1.0/myorg/datasets/{YOUR_DATASET_ID}/refreshes |
| Method | POST |
| Authentication | Service Principal via Azure AD App Registration |
| Header | Content-Type: application/json |

### Activity 2 — Trigger Power Automate Alert Check

| Setting | Value |
|---|---|
| Type | Web Activity |
| URL | Your Power Automate HTTP trigger URL |
| Method | POST |
| Body | {"status": "pipeline_complete", "date": "@{utcnow()}"} |

### Activity 3 — Trigger Power BI Robots Job

| Setting | Value |
|---|---|
| Type | Web Activity |
| URL | Your Power BI Robots API endpoint |
| Method | POST |
| Body | {"job": "daily_manager_report", "date": "@{utcnow()}"} |

---

## Pipeline 4: pl_audit_and_monitor

*Purpose:* Log every pipeline run result for observability  
*Trigger:* Always runs after all other pipelines  
*Estimated Duration:* 1 minute

### Audit Table Structure

sql
CREATE TABLE config.pipeline_audit (
    audit_id        INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name   VARCHAR(100),
    run_date        DATE,
    status          VARCHAR(20),
    records_loaded  INT,
    error_message   VARCHAR(500),
    duration_sec    INT,
    logged_at       DATETIME DEFAULT GETDATE()
);


### What Gets Logged Every Run

| Column | Example Value |
|---|---|
| pipeline_name | pl_transform_bronze_to_gold |
| run_date | 2024-01-15 |
| status | SUCCESS or FAILED |
| records_loaded | 1250 |
| error_message | NULL if success, error text if failed |
| duration_sec | 487 |

---

## Linked Services Configuration

### ls_http_call_api

json
{
  "name": "ls_http_call_api",
  "type": "HttpServer",
  "typeProperties": {
    "url": "https://raw.githubusercontent.com",
    "authenticationType": "Anonymous"
  }
}


### ls_http_ticket_api

json
{
  "name": "ls_http_ticket_api",
  "type": "HttpServer",
  "typeProperties": {
    "url": "https://api.mockaroo.com",
    "authenticationType": "Anonymous"
  }
}


### ls_azure_sql

json
{
  "name": "ls_azure_sql",
  "type": "AzureSqlDatabase",
  "typeProperties": {
    "connectionString": "Stored securely in Azure Key Vault",
    "server": "novacare-server.database.windows.net",
    "database": "novacare-analytics",
    "authenticationType": "ServicePrincipal"
  }
}


### ls_sql_server_hr

json
{
  "name": "ls_sql_server_hr",
  "type": "SqlServer",
  "typeProperties": {
    "connectionString": "Stored securely in Azure Key Vault",
    "server": "on-premises-hr-server",
    "database": "HR_System",
    "authenticationType": "Windows"
  }
}


---

## Incremental Loading Strategy

| Step | Action |
|---|---|
| Before pipeline runs | Read last_successful_run from config.pipeline_watermarks |
| During extraction | WHERE modified_date > last_successful_run |
| After successful run | UPDATE watermark to current UTC time |
| If run fails | Watermark NOT updated — full re-process on next run |

### Watermark Table

sql
SELECT * FROM config.pipeline_watermarks;

-- Example output:
-- pipeline_name          last_successful_run     last_run_status
-- call_api_extract       2024-01-15 06:14:32     SUCCESS
-- ticket_api_extract     2024-01-15 06:15:10     SUCCESS
-- employee_extract       2024-01-15 06:13:58     SUCCESS


---

## Error Handling Strategy

| Scenario | Action Taken |
|---|---|
| API timeout | Retry 3 times with 5 minute delay between attempts |
| Invalid data in Bronze | Route to quarantine table, send alert, continue pipeline |
| Stored procedure failure | Log to audit table, stop pipeline, email manager |
| Power BI refresh failure | Retry once after 10 minutes, log warning if fails again |
| Watermark table missing | Pipeline fails with descriptive error message |

---

## Daily Pipeline Schedule Summary

| Time (UTC) | Pipeline | Action |
|---|---|---|
| 6:00 AM | pl_extract_api_data | Pull from APIs and SQL Server |
| 7:00 AM | pl_transform_bronze_to_gold | Clean, validate, load star schema |
| 8:00 AM | pl_refresh_and_deliver | Refresh Power BI, send alerts, deliver PDFs |
| 8:05 AM | pl_audit_and_monitor | Log all run results |
| 9:00 AM | Power Automate | Check SLA thresholds, send breach alerts |