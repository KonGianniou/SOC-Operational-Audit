# =============================================================================
#  Security Operations Center (SOC) — Alarm Signal Analysis
#  Author  : Konstantina Gianniou
# =============================================================================

### Packages ###
install.packages(c("readxl", "dplyr", "tidyr", "lubridate", "stringr", "forcats",
                   "ggplot2", "scales", "patchwork", "ggtext", "viridis",
                   "broom", "knitr"))

library(readxl);library(dplyr);library(tidyr);library(lubridate);library(stringr);library(forcats);
library(ggplot2);library(scales);library(patchwork);library(ggtext);library(viridis);library(broom);library(knitr)

### Data cleaning ###

data=read_excel("SOC_Enhanced_Dataset.xlsx", sheet = "SOC_Alarms")

df=data %>%
  mutate(
    Date             = as.Date(Date),
    Month            = floor_date(Date, "month"),
    Month_Label      = format(Date, "%b %Y"),
    Week             = floor_date(Date, "week"),
    Hour             = as.integer(str_extract(Time, "^\\d+")),
    is_incident      = (Incident == "Yes"),
    is_false_alarm   = (!is_incident & False_Alarm_Reason != "N/A"),
    police_called    = (Police_Called == "Yes"),
    fire_called      = (Fire_Department_Called == "Yes"),
    escalated        = (Escalated == "Yes"),
    Priority_Level   = factor(Priority_Level,
                              levels = c("Low","Medium","High","Critical"),
                              ordered = TRUE),
    Agent_Seniority  = factor(Agent_Seniority,
                              levels = c("Junior","Mid","Senior"),
                              ordered = TRUE),
    Shift            = factor(Shift, levels = c("1st","2nd","3rd")),
    FA_Reason        = ifelse(False_Alarm_Reason == "N/A" | is.na(False_Alarm_Reason),
                              NA_character_, False_Alarm_Reason)
  )

cat(sprintf("Records loaded   : %d\n",  nrow(df)))
cat(sprintf("Date range       : %s → %s\n", min(df$Date), max(df$Date)))
cat(sprintf("Agents           : %s\n",
            paste(sort(unique(df$Handled_By)), collapse = ", ")))
cat(sprintf("Alarm types      : %s\n",
            paste(sort(unique(df$Alarm_Type)), collapse = ", ")))
cat(sprintf("Incident rate    : %.1f%%\n", mean(df$is_incident)*100))
cat(sprintf("False alarm rate : %.1f%%\n", mean(df$is_false_alarm, na.rm=TRUE)*100))


### Pallete for dashboard ###

COL_BG="#0D1117"
COL_PANEL="#161B22"
COL_GRID="#21262D"
COL_TEXT="#E6EDF3"
COL_MUTED="#8B949E"
COL_ACCENT="#F78166"   
COL_SAFE="#3FB950"  
COL_INFO="#58A6FF"   
COL_WARN="#E3B341" 

priority_cols=c(
  "Low"      = "#3FB950",
  "Medium"   = "#E3B341",
  "High"     = "#F0883E",
  "Critical" = "#F85149"
)

alarm_cols=c(
  "Burglary"     = "#F85149",
  "Fire"         = "#F0883E",
  "Panic Button" = "#E3B341",
  "Tamper"       = "#58A6FF",
  "Technical"    = "#8B949E"
)

agent_cols=c(
  E01="#58A6FF", E02="#79C0FF",
  E03="#3FB950", E04="#56D364", E05="#2EA043", E10="#85E89D",
  E06="#F85149", E07="#FF7B72", E08="#F0883E", E09="#FFA657"
)

seniority_cols=c("Senior"="#58A6FF", "Mid"="#3FB950", "Junior"="#F85149")

library(ggplot2)

soc_theme= theme_minimal(base_family = "mono") +
  theme(
    plot.background    = element_rect(fill = COL_BG,    colour = NA),
    panel.background   = element_rect(fill = COL_PANEL, colour = NA),
    panel.grid.major   = element_line(colour = COL_GRID, linewidth = 0.4),
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(colour = COL_TEXT,  face="bold", size=13),
    plot.subtitle      = element_text(colour = COL_MUTED, size=9.5,
                                      margin = margin(b=10)),
    plot.caption       = element_text(colour = COL_MUTED, size=7.5,
                                      margin = margin(t=8)),
    axis.title         = element_text(colour = COL_MUTED, size=9),
    axis.text          = element_text(colour = COL_MUTED, size=8),
    legend.background  = element_rect(fill = COL_PANEL, colour = NA),
    legend.title       = element_text(colour = COL_TEXT,  size=9),
    legend.text        = element_text(colour = COL_MUTED, size=8),
    strip.background   = element_rect(fill = COL_GRID, colour = NA),
    strip.text         = element_text(colour = COL_TEXT, face="bold", size=9),
    plot.margin        = margin(14, 18, 14, 18)
  )

theme_set(soc_theme)


### KPIs ###

kpi=list(
  total_signals    = nrow(df),
  incident_rate    = mean(df$is_incident),
  false_alarm_rate = mean(df$is_false_alarm, na.rm = TRUE),
  escalation_rate  = mean(df$escalated),
  avg_response     = mean(df$Response_Time_Min),
  avg_resolution   = mean(df$Resolution_Time_Min),
  critical_pct     = mean(df$Priority_Level == "Critical")
)

cat(sprintf("Total Signals      : %d\n",   kpi$total_signals))
cat(sprintf("Incident Rate      : %.1f%%\n", kpi$incident_rate*100))
cat(sprintf("False Alarm Rate   : %.1f%%\n", kpi$false_alarm_rate*100))
cat(sprintf("Escalation Rate    : %.1f%%\n", kpi$escalation_rate*100))
cat(sprintf("Avg Response Time  : %.1f min\n", kpi$avg_response))
cat(sprintf("Avg Resolution Time: %.1f min\n", kpi$avg_resolution))
cat(sprintf("Critical Signals   : %.1f%%\n", kpi$critical_pct*100))


### Agent performance ###

agent_summary=df %>%
  group_by(Handled_By, Agent_Seniority) %>%
  summarise(
    Total_Signals      = n(),
    Incidents          = sum(is_incident),
    Incident_Rate_Pct  = round(mean(is_incident)*100, 1),
    False_Alarms       = sum(is_false_alarm, na.rm=TRUE),
    False_Alarm_Pct    = round(mean(is_false_alarm, na.rm=TRUE)*100, 1),
    Avg_Response_Min   = round(mean(Response_Time_Min), 2),
    Avg_Resolution_Min = round(mean(Resolution_Time_Min), 2),
    Escalations        = sum(escalated),
    .groups = "drop"
  ) %>%
  arrange(Agent_Seniority, Handled_By)

library(knitr)

cat("\n── AGENT PERFORMANCE SUMMARY ────────────────────────────────────────────\n")
print(kable(agent_summary, format = "simple"))


### Plots ###
p1=df %>%
  count(Alarm_Type, Priority_Level) %>%
  group_by(Alarm_Type) %>%
  mutate(total = sum(n), pct = n/total) %>%
  ggplot(aes(x = fct_reorder(Alarm_Type, total, .desc=FALSE),
             y = n, fill = Priority_Level)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = n, group = Priority_Level),
            position = position_stack(vjust = 0.5),
            size = 2.8, colour = COL_BG, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = priority_cols,
                    guide  = guide_legend(reverse=TRUE)) +
  scale_y_continuous(expand = expansion(mult=c(0,0.05))) +
  labs(
    title    = "Alarm Volume by Type & Priority Level",
    subtitle = "Stacked count — label shows signal count per priority tier",
    x = NULL, y = "Number of Signals", fill = "Priority"
  );p1

p2=df %>%
  mutate(Handled_By = fct_reorder(Handled_By, Response_Time_Min, median)) %>%
  ggplot(aes(x = Handled_By, y = Response_Time_Min, fill = Agent_Seniority)) +
  geom_violin(alpha = 0.35, colour = NA, trim = FALSE) +
  geom_boxplot(width = 0.25, outlier.shape = 21, outlier.size = 1.5,
               outlier.colour = NA, outlier.fill = COL_ACCENT,
               colour = COL_MUTED, linewidth = 0.6) +
  stat_summary(fun = mean, geom = "point", shape = 18,
               size = 3.5, colour = COL_WARN) +
  scale_fill_manual(values = seniority_cols) +
  scale_y_continuous(breaks = seq(0, 30, 5)) +
  labs(
    title    = "Response Time Distribution by Agent",
    subtitle = "Diamond = mean · Box = IQR · Colour = seniority tier",
    x = NULL, y = "Response Time (minutes)", fill = "Seniority"
  ) +
  theme(legend.position = "top");p2

library(scales)

p3=agent_summary %>%
  mutate(
    Handled_By = fct_reorder(Handled_By, False_Alarm_Pct),
    flag = ifelse(False_Alarm_Pct > mean(False_Alarm_Pct) + sd(False_Alarm_Pct),
                  "Above threshold", "Normal")
  ) %>%
  ggplot(aes(x = Handled_By, y = False_Alarm_Pct, fill = flag)) +
  geom_col(width = 0.65) +
  geom_hline(aes(yintercept = mean(agent_summary$False_Alarm_Pct)),
             colour = COL_WARN, linetype = "dashed", linewidth = 0.8) +
  geom_hline(aes(yintercept = mean(agent_summary$False_Alarm_Pct) +
                   sd(agent_summary$False_Alarm_Pct)),
             colour = COL_ACCENT, linetype = "dotted", linewidth = 0.8) +
  geom_text(aes(label = paste0(False_Alarm_Pct, "%")),
            hjust = -0.2, size = 3.2, colour = COL_TEXT, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = c("Above threshold" = COL_ACCENT,
                                "Normal"          = COL_INFO)) +
  scale_y_continuous(limits = c(0, 90), labels = label_percent(scale=1)) +
  labs(
    title    = "False Alarm Rate by Agent",
    subtitle = "Dashed = fleet mean · Dotted = mean + 1 SD (alert threshold)",
    x = NULL, y = "False Alarm Rate (%)", fill = NULL,
    caption  = "False alarms = non-incident signals with a logged reason"
  ) +
  theme(legend.position = "top");p3

p4=df %>%
  filter(!is.na(FA_Reason)) %>%
  count(FA_Reason, Alarm_Type) %>%
  mutate(FA_Reason = fct_reorder(FA_Reason, n, sum)) %>%
  ggplot(aes(x = FA_Reason, y = n, fill = Alarm_Type)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = n, group = Alarm_Type),
            position = position_stack(vjust = 0.5),
            size = 2.5, colour = COL_BG, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = alarm_cols) +
  scale_y_continuous(expand = expansion(mult=c(0,0.05))) +
  labs(
    title    = "False Alarm Root Causes",
    subtitle = "Colour = alarm type that triggered the false event",
    x = NULL, y = "Count", fill = "Alarm Type"
  );p4

monthly_trend=df %>%
  group_by(Month, Month_Label) %>%
  summarise(
    Total     = n(),
    Incidents = sum(is_incident),
    Inc_Rate  = mean(is_incident),
    FA_Rate   = mean(is_false_alarm, na.rm=TRUE),
    Avg_RT    = mean(Response_Time_Min),
    .groups   = "drop"
  ) %>%
  arrange(Month)

p5_bar=monthly_trend %>%
  pivot_longer(c(Incidents, Total), names_to = "type", values_to = "n") %>%
  filter(type == "Total") %>%
  ggplot(aes(x = Month_Label, y = n)) +
  geom_col(fill = COL_INFO, width = 0.6, alpha = 0.7) +
  geom_col(data = monthly_trend %>%
             mutate(n = Incidents, Month_Label = Month_Label),
           aes(x = Month_Label, y = n),
           fill = COL_ACCENT, width = 0.6, inherit.aes = FALSE) +
  geom_text(data = monthly_trend, aes(x = Month_Label, y = Total + 5,
            label = Total), colour = COL_TEXT, size = 3, fontface="bold",
            inherit.aes = FALSE) +
  labs(x = NULL, y = "Signals", subtitle = "Blue = total · Red = incidents") +
  theme(plot.subtitle = element_text(size=8))

p5_line=monthly_trend %>%
  pivot_longer(c(Inc_Rate, FA_Rate), names_to="metric", values_to="rate") %>%
  mutate(metric = recode(metric,
    "Inc_Rate" = "Incident Rate",
    "FA_Rate"  = "False Alarm Rate")) %>%
  ggplot(aes(x = Month_Label, y = rate, colour = metric, group = metric)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3, shape = 21, fill = COL_PANEL, stroke = 1.5) +
  geom_text(aes(label = percent(rate, accuracy=0.1)),
            vjust = -1.2, size = 2.8, show.legend = FALSE) +
  scale_colour_manual(values = c("Incident Rate" = COL_ACCENT,
                                 "False Alarm Rate" = COL_WARN)) +
  scale_y_continuous(labels = percent_format(), limits = c(0.1, 0.85)) +
  labs(x = NULL, y = "Rate", colour = NULL) +
  theme(legend.position = "top", plot.subtitle = element_blank())

library(patchwork)

p5=(p5_bar / p5_line) +
  plot_annotation(
    title    = "Monthly Signal Volume & Rate Trends",
    subtitle = "Jan–Jun 2025",
    theme = theme(
      plot.title    = element_text(colour=COL_TEXT, face="bold", size=13),
      plot.subtitle = element_text(colour=COL_MUTED, size=9),
      plot.background = element_rect(fill=COL_BG, colour=NA)
    )
  );p5

shift_agent=df %>%
  group_by(Handled_By, Shift) %>%
  summarise(
    avg_response = mean(Response_Time_Min),
    n            = n(),
    inc_rate     = mean(is_incident),
    .groups = "drop"
  )

p6=shift_agent %>%
  ggplot(aes(x = Shift, y = fct_rev(Handled_By), fill = avg_response)) +
  geom_tile(colour = COL_BG, linewidth = 1.5) +
  geom_text(aes(label = sprintf("%.1f\n(n=%d)", avg_response, n)),
            size = 2.8, colour = COL_BG, fontface = "bold", lineheight = 1.1) +
  scale_fill_gradient2(
    low      = COL_SAFE,
    mid      = COL_WARN,
    high     = COL_ACCENT,
    midpoint = 7,
    name     = "Avg Response\n(min)"
  ) +
  labs(
    title    = "Average Response Time: Agent × Shift",
    subtitle = "Cell = mean response time (min) · n = signal count",
    x = "Shift", y = NULL
  ) +
  theme(panel.grid = element_blank());p6

p7=df %>%
  group_by(Alarm_Type, Priority_Level) %>%
  summarise(
    total     = n(),
    incidents = sum(is_incident),
    inc_rate  = incidents / total,
    .groups   = "drop"
  ) %>%
  ggplot(aes(x = Priority_Level, y = inc_rate,
             colour = Alarm_Type, group = Alarm_Type)) +
  geom_line(linewidth = 1.2, alpha = 0.85) +
  geom_point(size = 4, shape = 21, aes(fill = Alarm_Type),
             colour = COL_PANEL, stroke = 1.5) +
  geom_text(aes(label = percent(inc_rate, accuracy=1)),
            vjust = -1.3, size = 2.7, show.legend = FALSE) +
  scale_colour_manual(values = alarm_cols) +
  scale_fill_manual(values = alarm_cols) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1.05)) +
  labs(
    title    = "Incident Confirmation Rate by Alarm Type & Priority",
    subtitle = "How often each alarm type/priority results in a real incident",
    x = "Priority Level", y = "Incident Rate", colour = "Alarm Type",
    fill = "Alarm Type"
  ) +
  theme(legend.position = "right");p7

p8=df %>%
  filter(Handled_By %in% c("E08","E06","E07","E09")) %>%   # Junior peers for comparison
  group_by(Handled_By, Month, Month_Label) %>%
  summarise(avg_rt = mean(Response_Time_Min), n = n(), .groups="drop") %>%
  arrange(Month) %>%
  ggplot(aes(x = Month, y = avg_rt, colour = Handled_By, group = Handled_By)) +
  geom_vline(xintercept = as.numeric(as.Date("2025-04-01")),
             linetype = "dashed", colour = COL_WARN, linewidth = 0.8) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3.5, shape = 21, aes(fill=Handled_By),
             colour=COL_PANEL, stroke=1.5, show.legend=FALSE) +
  annotate("text", x = as.Date("2025-04-05"), y = 22,
           label = "E08 degradation\nstarts Apr", colour=COL_WARN,
           size = 2.8, hjust=0, lineheight=1.2) +
  scale_colour_manual(values = agent_cols) +
  scale_fill_manual(values = agent_cols) +
  scale_x_date(date_labels="%b", date_breaks="1 month") +
  scale_y_continuous(breaks=seq(0,30,5)) +
  labs(
    title    = "⚠  Agent E08: Response Time Degradation",
    subtitle = "Junior agent cohort (E06–E09) — monthly average response time",
    x = NULL, y = "Avg Response Time (min)", colour = "Agent"
  );p8

p9=df %>%
  group_by(Client_Type) %>%
  summarise(
    total      = n(),
    fa_count   = sum(is_false_alarm, na.rm=TRUE),
    fa_rate    = fa_count / total,
    inc_rate   = mean(is_incident),
    .groups = "drop"
  ) %>%
  arrange(fa_rate) %>%
  mutate(Client_Type = fct_reorder(Client_Type, fa_rate)) %>%
  pivot_longer(c(fa_rate, inc_rate), names_to="metric", values_to="rate") %>%
  mutate(metric = recode(metric,
    "fa_rate"  = "False Alarm Rate",
    "inc_rate" = "Incident Rate")) %>%
  ggplot(aes(x = Client_Type, y = rate, fill = metric)) +
  geom_col(position = position_dodge(width = 0.65), width = 0.55) +
  geom_text(aes(label = percent(rate, accuracy=0.1)),
            position = position_dodge(width=0.65),
            vjust = -0.4, size = 2.8, colour = COL_TEXT, fontface="bold") +
  scale_fill_manual(values = c("False Alarm Rate"=COL_WARN,
                                "Incident Rate"   =COL_ACCENT)) +
  scale_y_continuous(labels = percent_format(), limits=c(0,0.85)) +
  labs(
    title    = "False Alarm vs Incident Rate by Client Type",
    subtitle = "Grouped comparison across all 6 client categories",
    x = NULL, y = "Rate", fill = NULL
  ) +
  theme(legend.position = "top");p9

### Dashboard ###

dashboard=(p1 | p3) / (p2) / (p7 | p9) +
  plot_annotation(
    title    = "SOC ALARM INTELLIGENCE DASHBOARD",
    subtitle = "Security Operations Center · Jan–Jun 2025 · 1,200 Signals · 10 Agents",
    theme    = theme(
      plot.background = element_rect(fill=COL_BG, colour=NA),
      plot.title      = element_text(colour=COL_ACCENT, face="bold", size=17,
                                     family="mono"),
      plot.subtitle   = element_text(colour=COL_MUTED, size=10, family="mono",
                                     margin=margin(b=12))
    )
  );dashboard


### Analysis ###

# ANOVA: Response time by Agent
cat("── A. One-Way ANOVA: Response Time ~ Agent ─────────────────────\n")
anova_agent <- aov(Response_Time_Min ~ Handled_By, data = df)
print(summary(anova_agent))

# ANOVA: Response time by Seniority
cat("\n── B. One-Way ANOVA: Response Time ~ Seniority ─────────────────\n")
anova_sen <- aov(Response_Time_Min ~ Agent_Seniority, data = df)
print(summary(anova_sen))

# Kruskal-Wallis: Seniority vs Response
cat("\n── C. Kruskal-Wallis: Response Time ~ Seniority (non-parametric) \n")
kw <- kruskal.test(Response_Time_Min ~ Agent_Seniority, data=df)
print(kw)

# Chi-square: Is false alarm rate independent of Shift?
cat("\n── D. Chi-Square: False Alarm vs Shift ─────────────────────────\n")
fa_shift_tbl <- table(df$is_false_alarm, df$Shift)
print(chisq.test(fa_shift_tbl))

#Chi-square: Incident rate vs Client Type
cat("\n── E. Chi-Square: Incident Rate vs Client Type ──────────────────\n")
inc_ct_tbl <- table(df$is_incident, df$Client_Type)
print(chisq.test(inc_ct_tbl))

# Spearman: Response time vs Priority
cat("\n── F. Spearman Correlation: Response Time vs Priority (numeric) ─\n")
df_cor <- df %>% mutate(priority_num = as.integer(Priority_Level))
cor_res <- cor.test(df_cor$Response_Time_Min, df_cor$priority_num,
                    method = "spearman")
cat(sprintf("ρ = %.4f,  p-value = %.6f\n", cor_res$estimate, cor_res$p.value))

# Logistic regression: Predictors of an incident
cat("\n── G. Logistic Regression: Incident ~ Priority + Alarm + Seniority\n")
logit=glm(is_incident ~ Priority_Level + Alarm_Type + Agent_Seniority,
             data   = df,
             family = binomial(link = "logit"))
library(broom)
tidy_logit=tidy(logit, exponentiate = TRUE, conf.int = TRUE) %>%
  mutate(across(where(is.numeric), ~round(.x, 4))) %>%
  rename(OddsRatio = estimate)
print(kable(tidy_logit, format = "simple"))
cat(sprintf("\nLogit model AIC : %.2f\n", AIC(logit)))
cat(sprintf("Null deviance   : %.2f (df=%d)\n",
            logit$null.deviance, logit$df.null))
cat(sprintf("Residual deviance: %.2f (df=%d)\n",
            logit$deviance, logit$df.residual))

# E08 specific t-test: before vs after April
cat("\n── H. T-Test: E08 Response Time Before vs After April 2025 ─────\n")
e08=df %>% filter(Handled_By == "E08") %>%
  mutate(period = ifelse(Date < as.Date("2025-04-01"), "Before Apr", "From Apr"))
t_e08=t.test(Response_Time_Min ~ period, data = e08, var.equal = FALSE)
print(t_e08)


