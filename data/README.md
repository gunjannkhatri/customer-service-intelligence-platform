# Data Sources

## How Sample Data Was Created

All data in this repository is synthetic.
No real customer, employee, or business data is used.

---

## File 1: employee_data_sample.csv

*Source:* Derived from IBM HR Analytics Dataset
*Link:* https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset
*Rows in sample:* 30
*Columns used:*
- employee_id, employee_name, department, job_role
- hire_date, monthly_income, is_active

*Note:* Names replaced with synthetic names.
Employee IDs re-mapped to match call and ticket data.

---

## File 2: ticket_data_sample.csv

*Source:* Customer Support Ticket Dataset
*Link:* https://www.kaggle.com/datasets/suraj520/customer-support-ticket-dataset
*Rows in sample:* 50
*Columns used:*
- ticket_id, agent_id, ticket_date, priority
- ticket_type, status, resolution_time_hrs
- sla_target_hrs, csat_rating

---

## File 3: call_data_sample.json

*Source:* Synthetic data generated via Mockaroo
*Link:* https://mockaroo.com
*Rows in sample:* 50
*Fields:*
- agent_id, call_date, calls_offered, calls_handled
- calls_abandoned, avg_handle_time_sec
- avg_hold_time_sec, csat_score

---

## Full Dataset Instructions

To work with full data:

1. Download IBM HR dataset from Kaggle link above
2. Download Customer Support Ticket dataset from Kaggle link above
3. Generate call data from Mockaroo using schema in
   data/mockaroo_schema.json
4. Load into bronze tables using ADF or manual SQL insert