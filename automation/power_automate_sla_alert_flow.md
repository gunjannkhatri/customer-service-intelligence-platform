# Power Automate Flows — Automation Documentation

---

## Flow 1: NovaCare SLA Breach Alert

### Flow Summary

| Setting | Value |
|---|---|
| Flow Name | NovaCare — SLA Breach Alert |
| Trigger | Recurrence — Every day at 9:00 AM |
| Purpose | Alert managers when agents fall below SLA threshold |
| Connector 1 | SQL Server (read KPI data) |
| Connector 2 | Outlook (send email alert) |
| Connector 3 | Microsoft Teams (post channel message) |

---

### Step by Step Flow Configuration

#### Trigger — Recurrence

Interval    : 1
Frequency   : Day
Start Time  : 9:00 AM
Time Zone   : Your local time zone


#### Step 1 — Get rows from SQL (SQL Server connector)

Action      : Execute a SQL query
Connection  : Your Azure SQL or local SQL connection
Query       :

SELECT
    e.employee_name      AS agent_name,
    e.department         AS department,
    COUNT(t.ticket_id)   AS total_tickets,
    SUM(CASE WHEN t.is_sla_met = 0 THEN 1 ELSE 0 END)
                         AS breached_tickets,
    ROUND(
        CAST(SUM(t.is_sla_met) AS FLOAT)
        / COUNT(t.ticket_id) * 100, 1
    )                    AS sla_compliance_pct
FROM ticket_data t
JOIN employees e ON t.agent_id = e.employee_id
WHERE t.ticket_date = CAST(GETDATE()-1 AS DATE)
GROUP BY e.employee_name, e.department
HAVING
    ROUND(
        CAST(SUM(t.is_sla_met) AS FLOAT)
        / COUNT(t.ticket_id) * 100, 1
    ) < 80
ORDER BY sla_compliance_pct ASC


#### Step 2 — Condition Check

Condition   : length(outputs('Execute_SQL')?['body']['value']) 
              is greater than 0
Meaning     : Only continue if there are at-risk agents


#### Step 3 — If YES: Send Email (Outlook connector)

Action      : Send an email (V2)

To          : manager@novacare.com

Subject     : ⚠️ SLA Alert — Agent Performance Below Threshold

Body        :
Hi Team,

The following agents had SLA compliance below 80% yesterday
and require immediate attention:

[Dynamic content — loop through SQL results]
Agent: @{items('Apply_to_each')?['agent_name']}
Department: @{items('Apply_to_each')?['department']}
SLA Compliance: @{items('Apply_to_each')?['sla_compliance_pct']}%
Breached Tickets: @{items('Apply_to_each')?['breached_tickets']}

---
Please review the full dashboard for details:
[Your Power BI dashboard link]

This is an automated alert from the NovaCare Analytics Platform.
Do not reply to this email.


#### Step 4 — If YES: Post Teams Message

Action      : Post message in a chat or channel (Teams connector)
Post As     : Flow Bot
Post In     : Channel
Team        : NovaCare Operations
Channel     : ops-alerts

Message     :
⚠️ SLA ALERT — @{utcNow('dd MMM yyyy')}

@{length(outputs('Execute_SQL')?['body']['value'])} agent(s) 
are below the 80% SLA compliance threshold today.

Check the dashboard immediately:
[Your Power BI link]


#### Step 5 — If NO: Do Nothing

No action needed — flow ends silently
No alert means all agents are meeting SLA targets


---

## Flow 2: Daily Manager Report Trigger

### Flow Summary

| Setting | Value |
|---|---|
| Flow Name | NovaCare — Daily Report Delivery |
| Trigger | Recurrence — Every weekday at 8:30 AM |
| Purpose | Confirm pipeline completed then trigger PDF delivery |
| Connector 1 | SQL Server (check audit table) |
| Connector 2 | HTTP (trigger Power BI Robots) |
| Connector 3 | Outlook (confirm delivery to managers) |

---

### Step by Step Flow Configuration

#### Trigger — Recurrence (Weekdays Only)

Interval    : 1
Frequency   : Week
On These Days: Monday, Tuesday, Wednesday, Thursday, Friday
Start Time  : 8:30 AM


#### Step 1 — Check Pipeline Completed Successfully

Action      : Execute a SQL query
Query       :

SELECT TOP 1
    pipeline_name,
    status,
    records_loaded,
    logged_at
FROM config.pipeline_audit
WHERE run_date = CAST(GETDATE() AS DATE)
  AND pipeline_name = 'pl_transform_bronze_to_gold'
  AND status = 'SUCCESS'
ORDER BY logged_at DESC


#### Step 2 — Condition: Did Pipeline Succeed?

Condition   : length(outputs('Check_Pipeline')?['body']['value'])
              is greater than 0


#### Step 3 — If YES: Trigger Power BI Robots

Action      : HTTP
Method      : POST
URL         : Your Power BI Robots API endpoint
Headers     : Content-Type: application/json
Body        :
{
  "job_name": "daily_manager_report",
  "triggered_by": "power_automate",
  "date": "@{utcNow()}"
}


#### Step 4 — If YES: Send Confirmation Email

Action      : Send an email
To          : manager@novacare.com
Subject     : ✅ Daily Report Ready — @{utcNow('dd MMM yyyy')}
Body        :
Hi,

Your daily NovaCare performance report is ready.

Pipeline completed at: 
@{outputs('Check_Pipeline')?['body']['value'][0]['logged_at']}

Records processed: 
@{outputs('Check_Pipeline')?['body']['value'][0]['records_loaded']}

View live dashboard: [Your Power BI link]
Your PDF report has been sent separately via Power BI Robots.

— NovaCare Analytics Platform


#### Step 5 — If NO: Send Pipeline Failure Alert

Action      : Send an email
To          : dataanalyst@novacare.com
Subject     : 🔴 Pipeline Failed — Report Not Delivered
Body        :
Hi,

The daily data pipeline did not complete successfully today.
The manager report has NOT been delivered.

Please check Azure Data Factory for errors.
Pipeline: pl_transform_bronze_to_gold
Date: @{utcNow('dd MMM yyyy')}

— Automated Alert


---

## Power BI Robots — Job Configuration

### Job 1: Daily Manager Report

| Setting | Value |
|---|---|
| Job Name | daily_manager_report |
| Schedule | Every weekday at 8:00 AM |
| Report | Customer Service Intelligence |
| Pages | Executive Overview (Page 2) |
| Format | PDF |
| Delivery | Email |
| Recipients | All department managers |
| Subject | Daily Ops Report — {date} |

### Job 2: Weekly Leadership Pack

| Setting | Value |
|---|---|
| Job Name | weekly_leadership_pack |
| Schedule | Every Monday at 7:00 AM |
| Report | Customer Service Intelligence |
| Pages | All 5 pages |
| Format | PDF |
| Delivery | Email |
| Recipients | C-suite and Operations Director |
| Subject | Weekly Performance Pack — Week {week_number} |

### Job 3: Monthly Performance Review

| Setting | Value |
|---|---|
| Job Name | monthly_performance_review |
| Schedule | 1st of every month at 7:00 AM |
| Report | Customer Service Intelligence |
| Pages | All 5 pages |
| Format | PDF |
| Delivery | Email + Save to SharePoint |
| Recipients | All managers and leadership |
| Subject | Monthly Performance Review — {month} {year} |