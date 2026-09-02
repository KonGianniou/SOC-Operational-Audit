# Security Operations Center — Alarm Signal Analysis

I spent a couple years working as a manager inside a Security Operations Center, and this project is built around the kind of analysis I actually did on the job: figuring out which agents were struggling, why false alarms kept happening, and which signals genuinely deserved to be escalated.

I can't share the real operational data, so this dataset is synthetic with 1,200 alarm signals, six months (Jan–Jun 2025), 10 agents and 5 alarm types, but I built it to reflect the patterns I saw in practice, including planting a realistic problem (an agent whose response times quietly get worse partway through the year) to demonstrate how I'd actually go about catching that kind of thing rather than just eyeballing a chart.

**Note:** this is a synthetic dataset generated for portfolio purposes. No real client, agent, or operational data is used anywhere in this project.

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/6abe1c63-c1f2-4a8b-8e02-6b675884e2ff" />


---

## Why this project

Security operations centers deal with a constant stream of alarm signals, and most of them turn out to be nothing — an animal walking past a sensor, a power blip, someone forgetting their door code. The real job is sorting the noise from the signal fast enough that when something genuine happens, it gets escalated immediately. That was my day-to-day for a while, both running a team of agents and digging into the data behind their performance.

This project reproduces the questions I actually asked as a manager running that kind of operation:

- Are some agents genuinely slower than others, or is it just noise?
- Is any single agent's false alarm rate high enough to be a real concern?
- Does the shift someone works on affect how they perform?
- What actually predicts whether an alarm turns into a real incident?
- Is Agent E08 getting worse over time, or does it just feel that way?
- Are false alarms tied to when a signal comes in, or is it something else entirely?

Everything in this repo is me working through those questions with actual statistical tests rather than guessing from a chart.

---

## The data

150 clients, 10 agents, six months of signals, 7 categories of false alarm cause. Each row is one alarm signal with the client, the alarm type, which agent handled it, how long it took them to respond and resolve it, and whether it turned out to be a real incident.

| Column | Type | What it means |
|---|---|---|
| `Signal_ID` | string | Unique ID for the signal (S00001–S01200) |
| `Client_ID` | string | Which client account triggered it (C2001–C2150) |
| `Client_Type` | category | Home, Office, Shop, Factory, Warehouse, School |
| `Alarm_Type` | category | Burglary, Fire, Panic Button, Tamper, Technical |
| `Technical_Signal` | string | The specific sensor event that fired |
| `Zone` | string | Physical zone within the premises |
| `Date` / `Time` | date/time | When the signal came in |
| `Shift` | category | 1st (07–14h), 2nd (15–22h), 3rd (23–06h) |
| `Priority_Level` | ordered | Low → Medium → High → Critical |
| `Handled_By` | string | Which agent took the signal (E01–E10) |
| `Agent_Seniority` | ordered | Junior → Mid → Senior |
| `Response_Time_Min` | integer | Minutes from signal to acknowledgement |
| `Resolution_Time_Min` | integer | Minutes from signal to case closed |
| `Incident` | binary | Was it a real incident? |
| `Police_Called` / `Fire_Department_Called` | binary | Which service got dispatched, if any |
| `Escalated` | binary | Did either service get called |
| `False_Alarm_Reason` | string | Root cause when it wasn't real |
| `Outcome_Category` | string | Human-readable closure label |

Seniority breakdown:
- **Senior:** E01, E02
- **Mid:** E03, E04, E05, E10
- **Junior:** E06, E07, E08, E09

---

## What's in the repo

```
soc-alarm-analysis/
│
├── SOC_Enhanced_Dataset.xlsx        # the dataset
├── SOC_Enhanced_Dataset.csv         # same thing, CSV
│
├── soc_analysis.R                   # the analysis script
│
├── plots/
│   ├── 00_soc_dashboard.png         # 4-panel summary dashboard
│   ├── 01_alarm_type_priority.png
│   ├── 02_agent_response_time.png
│   ├── 03_false_alarm_rate_agent.png
│   ├── 04_false_alarm_reasons.png
│   ├── 05_monthly_trends.png
│   ├── 06_heatmap_agent_shift.png
│   ├── 07_incident_rate_type_priority.png
│   ├── 08_e08_degradation.png
│   └── 09_client_type_rates.png
│
├── agent_performance_summary.csv    # per-agent KPI table
├── monthly_summary.csv
├── flagged_agents.csv               # agents past the alert thresholds
│
└── README.md
```

---

## Running it

You need R 4.2 or newer. The script installs any missing packages on first run (`readxl`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `forcats`, `ggplot2`, `scales`, `patchwork`, `viridis`, `broom`, `knitr`).

```r
setwd("/path/to/soc-alarm-analysis")
source("soc_analysis.R")
```

---

## The statistical tests, and why I picked each one

**Response time by agent (ANOVA)** — first question: do the 10 agents actually differ, or is what looks like a gap just random variation? This came back wildly significant (F = 361, p < 2e-16), so yes, agents genuinely differ.

**Response time by seniority (ANOVA + Kruskal-Wallis)** — I ran seniority two ways because response times are right-skewed (a handful of juniors have very long outlier times that would skew a plain ANOVA). Both tests agree: seniority matters a lot (Kruskal-Wallis χ² = 858.2, p < 2.2e-16). Senior agents respond roughly 4x faster than juniors on average.

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/a75a2322-10a9-4cc8-94ee-8e58c498404b" />


**False alarms vs shift (Chi-square)** — I expected the overnight shift to have a different false alarm profile, maybe more spooked-by-shadows animal triggers. It didn't (χ² = 0.19, p = 0.91). False alarm rate looks completely independent of shift, which points to the cause being on the client side, not the SOC's operations.

**Incident rate vs client type (Chi-square)** — same idea, different variable: does the type of building matter for how often a signal turns out to be real? Not significantly (χ² = 3.23, p = 0.66), though factories and warehouses do trend toward more severe incidents even if the rate itself isn't statistically different.

**Response time vs priority (Spearman)** — priority is ordinal, not continuous, so Spearman is the right tool here rather than Pearson. There's a real but modest relationship (ρ = -0.16, p < 0.001): higher-priority alarms do get faster responses, just not as strongly as I'd have guessed.

**Logistic regression — what predicts a real incident** — `Incident ~ Priority_Level + Alarm_Type + Agent_Seniority`, reported as odds ratios with 95% CIs. This is the one I found most useful: it quantifies, for example, how much more likely a Critical Burglary alarm is to be real compared to a Low-priority Technical one.

**Welch t-test — Agent E08 before vs after April** — this was the one I built the dataset around. I compared E08's Jan–Mar response times against Apr–Jun using Welch's version (unequal variance, since the pre-April sample is smaller). The difference is enormous and unambiguous (t = -11.5, p < 2.2e-16) — something changed for this agent partway through the year.

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/3f93ecc7-109d-46aa-ae17-e150050b6526" />


---

## What the analysis actually turned up

**Agents worth a closer look:**

| Agent | Seniority | Issue |
|---|---|---|
| E08 | Junior | Response time jumps 3–6 minutes after April and stays there — statistically confirmed, not just eyeballing a chart |
| E07 | Junior | Slowest average response time in the junior group, consistently, every month |
| E05 | Mid | Handles a disproportionate share of confirmed incidents — could be workload distribution, could be assignment bias, worth investigating either way |

Flags trigger automatically when an agent's response time, false alarm rate, or incident rate sits more than 1 standard deviation above the fleet average.

**False alarms:**
- About 65% of all signals are false alarms, which lines up with what I've read about real SOC operations
- Power outages, maintenance, and general environmental noise are the biggest root causes
- Tamper and Technical alarms are almost never real incidents (close to 0%)
- Warehouses and factories have fewer false alarms overall, but the incidents they do have tend to be more severe

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/ae5a5e20-a2a0-440c-b7ff-606b99aeb034" />


**Other things worth knowing:**
- Critical-priority Panic Button alarms turn into real incidents over 75% of the time — an automatic escalation policy for these specifically seems justified
- The 1st shift (mornings) sees the most volume, but overnight (3rd shift) gets the most Critical-priority signals
- False alarm rate doesn't move with shift — again, this looks like a client-side pattern, not an operations one

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/ef66f3b3-66ef-4f06-a62d-91e1cdf08048" />


<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/6e2ebaea-8337-40d0-acbf-d01f1a03df48" />


Volume held fairly steady month over month, with false alarm and incident rates both staying flat across the six-month window — a sign the underlying operational patterns are stable rather than drifting, which makes the E08 anomaly stand out even more.

<img width="1920" height="947" alt="image" src="https://github.com/user-attachments/assets/d9ebb048-81a5-404b-a628-e9ff8e5a9148" />


---


