# KPI Definitions

## Agent Performance Score (Composite — 0 to 100)

The Agent Performance Score is a weighted composite of 5 KPIs.
All components are normalized to a 0–100 scale before weighting.

### Formula
Agent Score =

(Call Handle Score × 0.25) +

(CSAT Score  × 0.25)

(SLA Compliance  × 0.20)

(Ticket Volume × 0.15) +

(Efficiency Score × 0.15)
---

## Component 1: Call Handle Score (Weight: 25%)

*Definition:* Percentage of offered calls that were handled
(not abandoned) by the agent.

*Formula:*
Call Handle Score = (Calls Handled / Calls Offered) × 100
*Target:* 95% handle rate = 95 score
*Data Source:* Call System API

---

## Component 2: CSAT Score (Weight: 25%)

*Definition:* Customer satisfaction rating normalized to 0–100.
Source ratings are on a 1–5 scale.

*Formula:*
CSAT Score Normalized = (Raw CSAT Rating / 5) × 100
*Target:* 4.5/5 = 90 score
*Data Source:* Call System API + Ticket System API

---

## Component 3: SLA Compliance Score (Weight: 20%)

*Definition:* Percentage of tickets resolved within the
SLA target time for that priority level.

*SLA Targets by Priority:*
| Priority | SLA Target |
|---|---|
| Critical | 4 hours |
| High | 8 hours |
| Medium | 24 hours |
| Low | 72 hours |

*Formula:*
SLA Compliance Score =

(Tickets Resolved Within SLA / Total Tickets Assigned) × 100
*Target:* 90% compliance = 90 score
*Data Source:* Ticket System API

---

## Component 4: Ticket Volume Score (Weight: 15%)

*Definition:* Tickets resolved as a percentage of the
daily target (10 tickets per agent per day).

*Formula:*
Ticket Volume Score = (Tickets Resolved / 10) × 100 Capped at 100
*Target:* 10 tickets/day = 100 score
*Data Source:* Ticket System API

---

## Component 5: Efficiency Score (Weight: 15%)

*Definition:* How efficiently the agent handles calls
relative to the 4-minute (240 second) target handle time.

*Formula:*
Efficiency Score = (240 / Avg Handle Time in Seconds) × 100 Capped at 100
*Target:* 240 seconds or less = 100 score
*Data Source:* Call System API

---

## Performance Bands

| Band | Score Range | Meaning |
|---|---|---|
| 🌟 STAR | 90–100 | Exceptional performer |
| 🟢 HIGH | 75–89 | Strong performer |
| 🔵 GOOD | 60–74 | Meeting expectations |
| 🟡 NEEDS WORK | 45–59 | Below target — coaching needed |
| 🔴 AT RISK | 0–44 | Urgent intervention required |

---

## Other KPIs

### Abandonment Rate
Abandonment Rate = (Calls Abandoned / Calls Offered) × 100 Alert threshold: > 10%
### Average Handle Time (AHT)
AHT = Total Handle Time / Calls Handled

Target: <240 seconds

Alert: > 360 seconds
### SLA Breach Cost (Estimated)
Breach Cost = Total Breached Tickets × $150 ($150 = estimated average penalty per breach)
### Month-over-Month Score Change
MoM Change = Current Month Avg Score - Prior Month Avg Score