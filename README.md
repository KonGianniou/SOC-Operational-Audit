🔴 Security Operations Center — Alarm Signal Analysis
> \*\*Portfolio project\*\* · Synthetic dataset · R statistical analysis  
> 1,200 alarm signals · January – June 2025 · 10 agents · 5 alarm types

SYNTHETIC DATA PRODUCED BY CLAUDE.AI FOR PORTFOLIO DEMONSTRATION
---

Project Overview

This project simulates the analytical workflow of a Security Operations Center (SOC) data analyst. Using a synthetic dataset of 1,200 alarm signals handled by 10 agents across six months, the analysis:

Audits agent performance across response time, false alarm handling, and incident rates


Detects underperforming agents and anomalous behaviour patterns using statistical thresholds

Analyses false alarm root causes by reason, client type, and alarm category

Identifies which alarm types and priorities are most likely to result in real incidents

Runs hypothesis tests to determine whether observed differences are statistically significant

---
Business Context

>Security operations centers handle hundreds of alarm signals per day. Not all are genuine threats — a significant proportion are false alarms triggered by animals, power outages, user errors, or environmental factors. Managing these efficiently while ensuring real incidents are escalated promptly is the core operational challenge.
>
Key performance questions this analysis answers:

>Do agents respond at significantly different speeds?	--> ANOVA + Kruskal-Wallis
>
>Is an agent's false alarm rate unusually high?	--> 	Z-score threshold flagging
>
>Does shift (day/evening/night) affect performance?	--> 	Agent × Shift heatmap
>
>What predicts whether an alarm becomes a real incident?	--> 	Logistic regression
>
>Is agent E08 degrading over time?	--> 	T-test before/after breakpoint
>
>Are false alarm rates independent of shift?	--> 	Chi-square test

---
Dataset

(1,200 rows)

Records	500	1,200

Date range Jan–Jun 2025 (6 months)

Agents	10 (E01–E10)

Clients	150

False alarm reasons	7 categories

Engineered signals	—	E08 response degradation after April

Signal types	10 

Data Dictionary


	--> `Signal\_ID`	string	Unique signal identifier (S00001–S01200)
	--> `Client\_ID`	string	Client account (C2001–C2150)
	--> `Client\_Type`	category	Home · Office · Shop · Factory · Warehouse · School
	--> `Alarm\_Type`	category	Burglary · Fire · Panic Button · Tamper · Technical
	--> `Technical\_Signal`	string	Specific sensor event that triggered the alarm
	--> `Zone`	string	Physical zone within the premises
	--> `Date`	date	Signal date (YYYY-MM-DD)
	--> `Time`	time	Signal time (HH:MM)
	--> `Shift`	category	1st (07–14h) · 2nd (15–22h) · 3rd (23–06h)
	--> `Priority\_Level`	ordered	Low → Medium → High → Critical
	--> `Handled\_By`	string	Agent ID (E01–E10)
	--> `Agent\_Seniority`	ordered	Junior → Mid → Senior
	--> `Response\_Time\_Min`	integer	Minutes from signal to agent acknowledgement
	--> `Resolution\_Time\_Min`	integer	Total minutes from signal to case closure (new)
	--> `Incident`	binary	Y/N — Was the alarm a real incident?
	--> `Police\_Called`	binary	Y/N — Police dispatched
	--> `Fire\_Department\_Called`	binary	Y/N — Fire dept dispatched
	--> `Escalated`	binary	Y/N — Either emergency service called (new)
	--> `False\_Alarm\_Reason`	string	Root cause if not a real incident; `N/A` for real events
	--> `Outcome\_Category`	string	Human-readable closure label (new)
  
Seniority assignment:
Senior — E01, E02
Mid — E03, E04, E05, E10
Junior — E06, E07, E08, E09

---
Repository Structure
```
soc-alarm-analysis/
│
├── SOC\_Enhanced\_Dataset.xlsx        # Enhanced dataset (1,200 rows)
├── SOC\_Enhanced\_Dataset.csv         # Same, CSV format
│
├── soc\_analysis.R                   # Main R analysis script (17 sections)
│
├── plots/
│   ├── 00\_soc\_dashboard.png         # Composite 4-panel portfolio dashboard
│   ├── 01\_alarm\_type\_priority.png   # Alarm volume by type \& priority
│   ├── 02\_agent\_response\_time.png   # Response time distributions (violin)
│   ├── 03\_false\_alarm\_rate\_agent.png # False alarm rate by agent + thresholds
│   ├── 04\_false\_alarm\_reasons.png   # Root cause breakdown
│   ├── 05\_monthly\_trends.png        # Monthly volume \& rate trends
│   ├── 06\_heatmap\_agent\_shift.png   # Agent × Shift response time heatmap
│   ├── 07\_incident\_rate\_type\_priority.png  # Incident confirmation rates
│   ├── 08\_e08\_degradation.png       # E08 response time over time (flag)
│   └── 09\_client\_type\_rates.png     # FA vs incident rate by client type
│
├── agent\_performance\_summary.csv    # Per-agent KPI table (output)
├── monthly\_summary.csv              # Monthly aggregates (output)
├── flagged\_agents.csv               # Agents exceeding alert thresholds (output)
│
└── README.md                        # This file
```
---
R Analysis
Prerequisites
R ≥ 4.2.0. All packages auto-install on first run.
Package	Purpose
`readxl`	Read `.xlsx` dataset
`dplyr`, `tidyr`	Data wrangling
`lubridate`	Date/time parsing
`stringr`, `forcats`	String manipulation & factor ordering
`ggplot2`	All visualisations
`scales`	Axis and label formatting
`patchwork`	Composite plot layouts
`viridis`	Perceptually uniform colour scales
`broom`	Tidy statistical model output
`knitr`	Console table formatting
How to Run
```r
# Set working directory to the project root
setwd("/path/to/soc-alarm-analysis")

# Run the full analysis
source("soc\_analysis.R")
```

Statistical Tests

The script performs 8 statistical analyses, each targeting a specific operational question:

A. ANOVA — Response Time by Agent
> Tests whether mean response time differs significantly across the 10 agents.
> `H₀`: All agents respond at the same average speed.  
> Significant result → at least one agent's response time is different from the fleet.

B. ANOVA — Response Time by Seniority

> Tests whether seniority tier (Junior/Mid/Senior) explains response time variation.  
> `H₀`: Response time is identical across seniority levels.

C. Kruskal-Wallis — Seniority vs Response Time (non-parametric)

> Non-parametric equivalent of ANOVA B. Used because response times are not normally distributed — they are right-skewed (juniors sometimes have very long times).

D. Chi-Square — False Alarm Rate vs Shift

> Tests whether the proportion of false alarms is independent of which shift the alarm arrived on.  
> `H₀`: False alarm rate is the same across shifts 1, 2, and 3.

E. Chi-Square — Incident Rate vs Client Type

> Tests whether certain client categories (Home, Factory, School, etc.) have significantly different real incident rates.  
> `H₀`: Incident occurrence is independent of client type.

F. Spearman Correlation — Response Time vs Priority

> Measures the monotonic association between alarm priority and response speed.  
> Spearman is used because Priority is ordinal (Low < Medium < High < Critical), not continuous.

G. Logistic Regression — Predictors of a Real Incident
```
Incident \~ Priority\_Level + Alarm\_Type + Agent\_Seniority
```
> Reports odds ratios with 95% confidence intervals. Quantifies: given a Critical Burglary alarm, how much more likely is it to be a real incident compared to a > > Low-priority Technical signal?  
> Model fit assessed via McFadden Pseudo-R² and AIC.

H. Welch T-Test — E08 Before vs After April 2025

> Targeted test for agent E08 specifically, comparing their average response time in Jan–Mar against Apr–Jun.  
> `H₀`: E08's mean response time did not change after April.  
> Welch's variant is used (unequal variance assumed — smaller sample pre-April).
> 
---
Key Findings

Agent Issues Detected

Agent	Seniority	Issue	Detail

> E08	Junior	Response time degradation	Avg response increases 3–6 min after April; statistically significant (p < 0.05 from T-test)

> E07	Junior	Consistently slow responses	Highest mean response time in junior cohort across all months

> E05	Mid	Elevated incident rate	Handles disproportionately high share of confirmed incidents — possible workload or assignment bias

Fleet benchmarks (automated flags trigger at):

> Response time > fleet mean + 1 SD
> 
> False alarm rate > fleet mean + 1 SD
> 
> Incident rate > fleet mean + 1 SD

False Alarm Intelligence

> ~65% of signals are false alarms — broadly consistent with industry benchmarks
> 
> Top false alarm causes: Animal, User error, Dust, Power outage
> 
> Wind/Vibration added as a new category — accounts for a measurable share of tamper signals
> 
> Tamper and Technical alarm types produce almost exclusively false alarms (≈0% incident rate)
> 
> Warehouse and Factory clients have lower false alarm rates but higher incident severity
> 
Operational Insights

> Panic Button alarms at Critical priority convert to real incidents >75% of the time → immediate escalation policy is justified
> 
> 1st shift (07–14h) handles the highest volume but not the most critical signals; 3rd shift (overnight) sees the most Critical-priority events
> 
> Response time strongly correlates with seniority (Kruskal-Wallis p < 0.001); Senior agents respond ~4× faster than juniors on average
> 
> False alarm rate does not vary significantly by shift (Chi-square p > 0.05) — suggesting the causes are client-side, not operational
---

This project uses a fully synthetic dataset. No real client or operational data is represented.
