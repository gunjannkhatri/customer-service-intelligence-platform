# DAX Measures — Customer Service Intelligence Platform

## Setup Instructions

Before creating measures, set up a dedicated measures table:


1. Open Power BI Desktop
2. Click Home → Enter Data
3. Create a blank table with one column called placeholder
4. Name the table: _Measures
5. Click Load
6. Right click _Measures table → New Measure
7. Create all measures below inside this table


---

## Section 1 — Core KPI Measures

### Avg Agent Score
dax
Avg Agent Score =
AVERAGE(call_data[csat_score_norm])


### SLA Compliance %
dax
SLA Compliance % =
DIVIDE(
    CALCULATE(
        COUNTROWS(ticket_data),
        ticket_data[is_sla_met] = 1
    ),
    COUNTROWS(ticket_data),
    0
) * 100


### Avg CSAT Score
dax
Avg CSAT Score =
AVERAGE(ticket_data[csat_rating])


### Total Tickets Resolved
dax
Total Tickets Resolved =
CALCULATE(
    COUNTROWS(ticket_data),
    ticket_data[status] = "Resolved"
)


### Total Calls Handled
dax
Total Calls Handled =
SUM(call_data[calls_handled])


### Total Calls Offered
dax
Total Calls Offered =
SUM(call_data[calls_offered])


### Abandonment Rate %
dax
Abandonment Rate % =
DIVIDE(
    SUM(call_data[calls_abandoned]),
    SUM(call_data[calls_offered]),
    0
) * 100


### Avg Handle Time (seconds)
dax
Avg Handle Time Sec =
AVERAGE(call_data[avg_handle_time_sec])


### Avg Handle Time (minutes)
dax
Avg Handle Time Min =
DIVIDE([Avg Handle Time Sec], 60, 0)


### Total SLA Breaches
dax
Total SLA Breaches =
CALCULATE(
    COUNTROWS(ticket_data),
    ticket_data[is_sla_met] = 0
)


### At Risk Agent Count
dax
At Risk Agent Count =
CALCULATE(
    DISTINCTCOUNT(call_data[agent_id]),
    call_data[handle_rate] < 0.80
)


### Active Agent Count
dax
Active Agent Count =
CALCULATE(
    COUNTROWS(employees),
    employees[is_active] = 1
)


---

## Section 2 — Scoring Measures

### Call Handle Score (0 to 100)
dax
Call Handle Score =
ROUND(
    MIN(
        DIVIDE(
            SUM(call_data[calls_handled]),
            SUM(call_data[calls_offered]),
            0
        ) * 100,
        100
    ),
    2
)


### CSAT Score Normalized (0 to 100)
dax
CSAT Score Normalized =
ROUND(
    DIVIDE([Avg CSAT Score], 5, 0) * 100,
    2
)


### SLA Compliance Score (0 to 100)
dax
SLA Compliance Score =
ROUND([SLA Compliance %], 2)


### Efficiency Score (0 to 100)
dax
Efficiency Score =
ROUND(
    MIN(
        DIVIDE(240, [Avg Handle Time Sec], 0) * 100,
        100
    ),
    2
)


### Agent Performance Score (Weighted Composite)
dax
Agent Performance Score =
ROUND(
    ([Call Handle Score]        * 0.25) +
    ([CSAT Score Normalized]    * 0.25) +
    ([SLA Compliance Score]     * 0.20) +
    ([Efficiency Score]         * 0.15) +
    (MIN(
        DIVIDE([Total Tickets Resolved], 10, 0) * 100,
        100
    )                           * 0.15),
    2
)


### Performance Band
dax
Performance Band =
SWITCH(
    TRUE(),
    [Agent Performance Score] >= 90, "STAR",
    [Agent Performance Score] >= 75, "HIGH",
    [Agent Performance Score] >= 60, "GOOD",
    [Agent Performance Score] >= 45, "NEEDS WORK",
    "AT RISK"
)


---

## Section 3 — Comparison and Trend Measures

### Department Avg Score
dax
Department Avg Score =
CALCULATE(
    [Agent Performance Score],
    ALLEXCEPT(employees, employees[department])
)


### Score vs Department Avg
dax
Score vs Dept Avg =
[Agent Performance Score] - [Department Avg Score]


### Company Avg Score
dax
Company Avg Score =
CALCULATE(
    [Agent Performance Score],
    ALL(employees)
)


### Score vs Company Avg
dax
Score vs Company Avg =
[Agent Performance Score] - [Company Avg Score]


---

## Section 4 — Period Comparison Measures

### SLA % Last Month
dax
SLA % Last Month =
CALCULATE(
    [SLA Compliance %],
    DATEADD(ticket_data[ticket_date], -1, MONTH)
)


### SLA % MoM Change
dax
SLA MoM Change =
[SLA Compliance %] - [SLA % Last Month]


### CSAT Last Month
dax
CSAT Last Month =
CALCULATE(
    [Avg CSAT Score],
    DATEADD(ticket_data[ticket_date], -1, MONTH)
)


### CSAT MoM Change
dax
CSAT MoM Change =
[Avg CSAT Score] - [CSAT Last Month]


---

## Section 5 — Alert and Status Measures

### SLA Status Label
dax
SLA Status Label =
SWITCH(
    TRUE(),
    [SLA Compliance %] >= 90, "ON TARGET",
    [SLA Compliance %] >= 80, "WARNING",
    "BREACH RISK"
)


### SLA Traffic Light Color
dax
SLA Traffic Light =
SWITCH(
    TRUE(),
    [SLA Compliance %] >= 90, "Green",
    [SLA Compliance %] >= 80, "Yellow",
    "Red"
)


### Score Trend Arrow
dax
Score Trend Arrow =
VAR _Change = [SLA MoM Change]
RETURN
SWITCH(
    TRUE(),
    _Change >  2, "▲ Improving",
    _Change < -2, "▼ Declining",
    "► Stable"
)


### AHT Status
dax
AHT Status =
SWITCH(
    TRUE(),
    [Avg Handle Time Sec] <= 240, "GOOD",
    [Avg Handle Time Sec] <= 360, "WARNING",
    "OVER TARGET"
)


---

## Section 6 — Leaderboard Measures

### Agent Rank Overall
dax
Agent Rank Overall =
RANKX(
    ALLSELECTED(employees[employee_name]),
    [Agent Performance Score],
    ,
    DESC,
    DENSE
)


### Agent Rank in Department
dax
Agent Rank In Department =
RANKX(
    ALLSELECTED(employees[employee_name]),
    [Agent Performance Score],
    ,
    DESC,
    DENSE
)


### Top Performer Name
dax
Top Performer Name =
CALCULATE(
    FIRSTNONBLANK(employees[employee_name], 1),
    TOPN(
        1,
        ALL(employees[employee_name]),
        [Agent Performance Score],
        DESC
    )
)


### Top Department
dax
Top Department =
CALCULATE(
    FIRSTNONBLANK(employees[department], 1),
    TOPN(
        1,
        ALL(employees[department]),
        [Agent Performance Score],
        DESC
    )
)


### Star Agent Count
dax
Star Agent Count =
CALCULATE(
    DISTINCTCOUNT(call_data[agent_id]),
    FILTER(
        VALUES(call_data[agent_id]),
        [Agent Performance Score] >= 90
    )
)


---

## Section 7 — Business Impact Measures

### Estimated SLA Breach Cost
dax
Estimated Breach Cost =
[Total SLA Breaches] * 150


### Tickets Breached This Month
dax
Tickets Breached This Month =
CALCULATE(
    [Total SLA Breaches],
    DATESMTD(ticket_data[ticket_date])
)


### Resolution Rate %
dax
Resolution Rate % =
DIVIDE(
    [Total Tickets Resolved],
    COUNTROWS(ticket_data),
    0
) * 100


---

## Section 8 — Conditional Formatting Measures

### Score Color (use in conditional formatting)
dax
Score Color =
SWITCH(
    TRUE(),
    [Agent Performance Score] >= 90, "#1DB954",
    [Agent Performance Score] >= 75, "#4CAF50",
    [Agent Performance Score] >= 60, "#2196F3",
    [Agent Performance Score] >= 45, "#FF9800",
    "#F44336"
)


### SLA Bar Color
dax
SLA Bar Color =
IF(
    [SLA Compliance %] >= 90,
    "#1DB954",
    IF(
        [SLA Compliance %] >= 80,
        "#FF9800",
        "#F44336"
    )
)