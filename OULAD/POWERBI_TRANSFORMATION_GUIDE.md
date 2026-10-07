# OULAD SQL → PowerBI Transformation Guide

## 1. Data Loading (PowerQuery)

Load the 7 CSV files from `Dataset/`:

| CSV | Table Name in PowerBI |
|------|----------------------|
| studentInfo.csv | dim_student |
| courses.csv | dim_course |
| assessments.csv | dim_assessment |
| vle.csv | dim_vle |
| studentRegistration.csv | fact_registration |
| studentAssessment.csv | fact_assessment |
| studentVle.csv | fact_student_vle |

### PowerQuery Transformations Needed

**dim_date** — Create a calendar dimension (not from CSV):
```
= Table.FromList({-200..300}, Splitter.SplitByNothing(), {"date_offset"})
  → Add column: week_number = Number.IntegerDivide([date_offset] + 200, 7)
  → Add column: day_of_week = Number.Mod([date_offset], 7)
  → Add column: day_name = {"Mon","Tue","Wed","Thu","Fri","Sat","Sun"}{[day_of_week]}
  → Add column: is_weekend = [day_of_week] >= 5
  → Add column: month = Date.Month(#date(2020,1,1) + #duration([date_offset] + 200, 0, 0, 0))
```

## 2. Relationship Model

```
dim_course (code_module, code_presentation)
    → 1:N → fact_registration (via code_module + code_presentation)
    → 1:N → dim_assessment (via code_module + code_presentation)
    → 1:N → dim_vle (via code_module + code_presentation)

dim_student (id_student)
    → 1:N → fact_registration (via id_student)
    → 1:N → fact_assessment (via id_student)
    → 1:N → fact_student_vle (via id_student)

dim_assessment (id_assessment)
    → 1:N → fact_assessment (via id_assessment)

dim_vle (id_site)
    → 1:N → fact_student_vle (via id_site)

dim_date (date_offset)
    → 1:N → fact_assessment (via date_submitted)
    → 1:N → fact_student_vle (via date)
    → 1:N → fact_registration (via date_registration, date_unregistration)
```

**Important**: In PowerBI, create a bridge table for `code_module_code_presentation` to link dim_course with dim_student (since dim_student also has code_module/code_presentation).

---

## 3. DAX Measures — Master Table

```dax
// ===== BASE MEASURES =====

Total Students = COUNTROWS(dim_student)

Total Passed =
CALCULATE(
    COUNTROWS(dim_student),
    dim_student[final_result] IN {"Pass", "Distinction"}
)

Total Withdrawn =
CALCULATE(
    COUNTROWS(dim_student),
    dim_student[final_result] = "Withdrawn"
)

Overall Pass Rate % =
DIVIDE([Total Passed], [Total Students], 0) * 100

Overall Withdrawal Rate % =
DIVIDE([Total Withdrawn], [Total Students], 0) * 100

Total Withdrawn (fact) =
COUNTROWS(fact_registration),
fact_registration[is_withdrawn] = 1

Avg Assessment Score =
AVERAGE(fact_assessment[score])

StdDev Score =
STDEV.P(fact_assessment[score])

Total Clicks =
SUM(fact_student_vle[sum_click])

Avg Clicks Per Record =
AVERAGE(fact_student_vle[sum_click])

Active Students (VLE) =
DISTINCTCOUNT(fact_student_vle[id_student])

Total Modules =
DISTINCTCOUNT(dim_course[code_module])

Total Presentations =
DISTINCTCOUNT(dim_course[code_presentation])
```

---

## 4. Analysis Sections → Measures + Visuals

### SECTION 1: OVERALL PASS RATES
**SQL Query 1**: Student count + percentage by final_result

```dax
// Measures
Student Count = COUNTROWS(dim_student)
Student % = DIVIDE([Student Count], CALCULATE([Student Count], ALL(dim_student))) * 100
```

**Visual**: Donut/ Pie chart
- Legend: `dim_student[final_result]`
- Values: `[Student Count]`
- Detail labels: percentage

---

### SECTION 2: PASS RATE BY DEMOGRAPHICS

**By Gender** (SQL query 2a):
```dax
Pass Rate by Gender =
VAR passed = CALCULATE([Total Passed])
VAR total = CALCULATE([Total Students])
RETURN DIVIDE(passed, total, 0) * 100
```
Visual: **Clustered bar chart** | Axis: `gender` | Values: `[Pass Rate by Gender]`, `[Total Students]`

**By Age Band** (SQL query 2b):
Visual: **Clustered column chart** | Axis: `age_band` | Values: `[Pass Rate by Age Band]`

**By Region (Top 10)** (SQL query 2c):
```dax
Pass Rate by Region =
VAR passed = CALCULATE([Total Passed])
VAR total = CALCULATE([Total Students])
RETURN DIVIDE(passed, total, 0) * 100
```
Visual: **Bar chart (Top N filter = 10)** | Axis: `region` | Values: `[Pass Rate by Region]`

**By Education Level** (SQL query 2d):
Visual: **Column chart** | Axis: `highest_education` | Values: `[Pass Rate by Education Level]`

**By IMD Band** (SQL query 2e):
Visual: **Line/Column chart** | Axis: `imd_band` (sorted) | Values: `[Pass Rate by IMD]`

**By Disability** (SQL query 2f):
Visual: **Donut chart** | Legend: `disability` | Values: `[Pass Rate by Disability]`

**By Previous Attempts** (SQL query 2g):
```dax
// Calculated column in dim_student
Attempt Group =
SWITCH(
    TRUE(),
    dim_student[num_of_prev_attempts] = 0, "First attempt",
    dim_student[num_of_prev_attempts] = 1, "1 previous",
    "2+ previous"
)
```
Visual: **Column chart** | Axis: `Attempt Group` | Values: `[Pass Rate]`

---

### SECTION 3: MODULE PERFORMANCE COMPARISON

```dax
// Measures
Enrolled Students = DISTINCTCOUNT(fact_registration[id_student])

Avg Assessment Score (Module) =
AVERAGE(fact_assessment[score])

Pass Rate (Module) =
VAR passed = CALCULATE(
    COUNTROWS(dim_student),
    dim_student[final_result] IN {"Pass", "Distinction"}
)
VAR enrolled = DISTINCTCOUNT(fact_registration[id_student])
RETURN DIVIDE(passed, enrolled, 0) * 100

Withdrawal Rate (Module) =
VAR withdrawn = CALCULATE(
    COUNTROWS(dim_student),
    dim_student[final_result] = "Withdrawn"
)
VAR enrolled = DISTINCTCOUNT(fact_registration[id_student])
RETURN DIVIDE(withdrawn, enrolled, 0) * 100
```

**Visual**: **Table/Matrix**
- Rows: `code_module`, `code_presentation`
- Values: `[Enrolled Students]`, `[Avg Assessment Score (Module)]`, `[Pass Rate (Module)]`, `[Withdrawal Rate (Module)]`

---

### SECTION 4: ASSESSMENT ANALYSIS

**By Assessment Type** (SQL query 4a):
```dax
Avg Score by Type = AVERAGE(fact_assessment[score])
StdDev Score by Type = STDEV.P(fact_assessment[score])
Min Score = MIN(fact_assessment[score])
Max Score = MAX(fact_assessment[score])
Banked Ratio =
DIVIDE(
    CALCULATE(COUNTROWS(fact_assessment), fact_assessment[is_banked] = 1),
    COUNTROWS(fact_assessment),
    0
)
```
Visual: **Table** with columns: `assessment_type`, `[Total Submissions]`, `[Avg Score by Type]`, `[StdDev]`, `[Min]`, `[Max]`, `[Banked Ratio]`

**Exam Score Distribution by Module** (SQL query 4b):
```dax
Avg Exam Score =
CALCULATE(
    AVERAGE(fact_assessment[score]),
    dim_assessment[assessment_type] = "Exam"
)
Exam StdDev = CALCULATE(STDEV.P(fact_assessment[score]), dim_assessment[assessment_type] = "Exam")
Exam Lower Bound = [Avg Exam Score] - [Exam StdDev]
Exam Upper Bound = [Avg Exam Score] + [Exam StdDev]
```
Visual: **Line chart** with error bars | Axis: `code_module` | Values: `[Avg Exam Score]`

---

### SECTION 5: VLE ENGAGEMENT ANALYSIS

**By Activity Type** (SQL query 5a):
```dax
Students Using = DISTINCTCOUNT(fact_student_vle[id_student])
Total Clicks = SUM(fact_student_vle[sum_click])
Avg Clicks = AVERAGE(fact_student_vle[sum_click])
% of Total Clicks =
DIVIDE([Total Clicks], CALCULATE([Total Clicks], ALL(dim_vle[activity_type]))) * 100
```
Visual: **Bar chart** | Axis: `activity_type` | Values: `[Total Clicks]`, `[Students Using]`

**VLE Engagement vs Final Result** (SQL query 5b):
```dax
Avg Total Clicks by Result =
AVERAGEX(
    dim_student,
    CALCULATE(SUM(fact_student_vle[sum_click]))
)

Avg Active Days by Result =
AVERAGEX(
    dim_student,
    CALCULATE(DISTINCTCOUNT(fact_student_vle[date]))
)

Avg Clicks Per Active Day =
DIVIDE([Avg Total Clicks by Result], [Avg Active Days by Result], 0)
```
Visual: **Clustered column chart** | Axis: `final_result` | Values: `[Avg Total Clicks]`, `[Avg Active Days]`

**Weekly VLE Pattern** (SQL query 5c):
```dax
Weekly Clicks =
SUM(fact_student_vle[sum_click])

Weekly Active Students =
DISTINCTCOUNT(fact_student_vle[id_student])

Weekly Avg Clicks Per Student =
DIVIDE([Weekly Clicks], [Weekly Active Students], 0)
```
Visual: **Line chart** | Axis: dim_date[week] (or date_offset) | Values: `[Weekly Clicks]`, `[Weekly Avg Clicks Per Student]`
- Add a trend line

---

### SECTION 6: CORRELATION — CLICKS vs SCORES

```dax
// Calculated column in dim_student (aggregate per student)
Student Total Clicks =
CALCULATE(
    SUM(fact_student_vle[sum_click]),
    ALLEXCEPT(dim_student, dim_student[id_student])
)

Student Active Days =
CALCULATE(
    DISTINCTCOUNT(fact_student_vle[date]),
    ALLEXCEPT(dim_student, dim_student[id_student])
)

Student Avg Score =
CALCULATE(
    AVERAGE(fact_assessment[score]),
    ALLEXCEPT(dim_student, dim_student[id_student])
)

// Engagement group (calc column in dim_student)
Engagement Group =
SWITCH(
    TRUE(),
    [Student Total Clicks] = 0, "No clicks",
    [Student Total Clicks] <= 500, "1-500 clicks",
    [Student Total Clicks] <= 2000, "501-2000 clicks",
    [Student Total Clicks] <= 5000, "2001-5000 clicks",
    "5000+ clicks"
)
```

**Visual**: **Clustered bar chart**
- Axis: `Engagement Group`
- Values: `AVERAGE(dim_student[Student Avg Score])`, `AVERAGE(dim_student[Student Active Days])`
- Or **Scatter chart**: X = `[Student Total Clicks]`, Y = `[Student Avg Score]`, play axis = `final_result`

---

### SECTION 7: WITHDRAWAL / DROPOUT ANALYSIS

**By Age Band x Gender** (SQL query 7a):
```dax
Withdrawal Rate =
DIVIDE(
    CALCULATE(COUNTROWS(dim_student), dim_student[final_result] = "Withdrawn"),
    COUNTROWS(dim_student),
    0
) * 100
```
Visual: **Matrix** | Rows: `age_band` | Columns: `gender` | Values: `[Withdrawal Rate]`

**Withdrawal Timing** (SQL query 7b):
```dax
// Calculated column in fact_registration
Withdrawal Timing =
SWITCH(
    TRUE(),
    fact_registration[days_registered] <= 30, "First month",
    fact_registration[days_registered] <= 60, "1-2 months",
    fact_registration[days_registered] <= 90, "2-3 months",
    fact_registration[days_registered] <= 120, "3-4 months",
    "4+ months"
)
```
Visual: **Pie/Donut chart** | Legend: `Withdrawal Timing` | Values: count of rows

---

### SECTION 8: HIGH PERFORMERS vs AT-RISK PROFILES

**High Achiever Profile** (SQL query 8a):
Visual: **Stacked bar chart** with slicers or **Decomposition Tree**
- Filter: `final_result = "Distinction"`
- Axis: `gender`, `age_band`, `highest_education`, `region` (drill-down)

**At-Risk Profile** (SQL query 8b):
```dax
// Calculated column in dim_student
At-Risk Rate =
VAR atRisk = CALCULATE(
    COUNTROWS(dim_student),
    dim_student[final_result] IN {"Fail", "Withdrawn"}
)
VAR total = COUNTROWS(dim_student)
RETURN DIVIDE(atRisk, total, 0) * 100
```
Visual: **Matrix** | Rows: `Attempt Group` | Columns: `disability`, `age_band` | Values: `[At-Risk Rate]`

---

### SECTION 9: SUBMISSION TIMING ANALYSIS

```dax
// Calculated column in fact_assessment
Submission Timing =
VAR deadline = RELATED(dim_assessment[date_deadline])
VAR submitted = fact_assessment[date_submitted]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(submitted) || ISBLANK(deadline), "Unknown",
        submitted < deadline - 5, "Early (5+ days early)",
        submitted <= deadline, "On time",
        submitted > deadline, "Late",
        "Unknown"
    )

// Measure
Avg Score by Timing = AVERAGE(fact_assessment[score])
```
Visual: **Clustered column chart** | Axis: `Submission Timing` | Values: count, `[Avg Score by Timing]`

---

### SECTION 10: MODULE ENGAGEMENT vs OUTCOME

```dax
VLE Penetration % =
DIVIDE(
    [Active Students (VLE)],
    [Enrolled Students],
    0
) * 100
```
Visual: **Scatter chart**
- X: `[Avg Clicks Per Record]` or `[VLE Penetration %]`
- Y: `[Pass Rate (Module)]`
- Detail: `code_module`
- Size: `[Enrolled Students]`

---

### SECTION 11: STUDENT SUCCESS PREDICTORS

```dax
// One measure per factor using CALCULATE pattern
Success Rate (Female) =
CALCULATE([Overall Pass Rate %], dim_student[gender] = "F")

Success Rate (Male) =
CALCULATE([Overall Pass Rate %], dim_student[gender] = "M")

Gender Impact = [Success Rate (Female)] - [Success Rate (Male)]

First Attempt Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[num_of_prev_attempts] = 0)

Repeat Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[num_of_prev_attempts] > 0)

First Attempt Impact = [First Attempt Pass Rate] - [Repeat Pass Rate]

No Disability Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[disability] = "N")

Disability Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[disability] = "Y")

Disability Impact = [No Disability Pass Rate] - [Disability Pass Rate]

HE Qualified Pass Rate =
CALCULATE([Overall Pass Rate %],
    dim_student[highest_education] = "HE Qualification" ||
    CONTAINSSTRING(dim_student[highest_education], "Degree")
)

No HE Pass Rate =
CALCULATE([Overall Pass Rate %],
    NOT (dim_student[highest_education] = "HE Qualification" ||
         CONTAINSSTRING(dim_student[highest_education], "Degree"))
)

HE Impact = [HE Qualified Pass Rate] - [No HE Pass Rate]

High IMD Pass Rate =
CALCULATE([Overall Pass Rate %],
    dim_student[imd_band] IN {"90-100%", "80-90%", "70-80%"}
)

Low IMD Pass Rate =
CALCULATE([Overall Pass Rate %],
    NOT dim_student[imd_band] IN {"90-100%", "80-90%", "70-80%"}
)

IMD Impact = [High IMD Pass Rate] - [Low IMD Pass Rate]
```

**Visual**: **Table**
- Rows: hardcoded factor names (create a disconnected table)
- Columns: `Success Rate (Factor=T)`, `Success Rate (Factor=F)`, `Impact`

Or use a **Waterfall chart** showing the impact deltas.

---

### SECTION 12: VLE ACTIVITY BY DAY OF WEEK

```dax
Clicks by Day = SUM(fact_student_vle[sum_click])
Unique Students by Day = DISTINCTCOUNT(fact_student_vle[id_student])
Avg Clicks by Day = AVERAGE(fact_student_vle[sum_click])
```

**Visual**: **Column chart** | Axis: `day_name` (sorted Mon-Sun) | Values: `[Clicks by Day]`

Add a **Card** for weekend vs weekday comparison:
```dax
Weekend Clicks =
CALCULATE([Clicks by Day],
    dim_date[is_weekend] = TRUE
)

Weekday Clicks =
CALCULATE([Clicks by Day],
    dim_date[is_weekend] = FALSE
)
```

---

### SECTION 13: STUDENT SEGMENTATION (RFM-like)

```dax
// Calculated columns in dim_student
Score Tier =
SWITCH(
    TRUE(),
    [Student Avg Score] >= 80, "High Scorer",
    [Student Avg Score] >= 50, "Medium Scorer",
    [Student Avg Score] > 0, "Low Scorer",
    "No Assessments"
)

VLE Engagement Tier =
SWITCH(
    TRUE(),
    [Student Active Days] = 0, "No VLE",
    [Student Active Days] <= 10, "Low VLE",
    [Student Active Days] <= 30, "Medium VLE",
    "High VLE"
)
```

**Visual**: **Matrix** | Rows: `Score Tier` | Columns: `VLE Engagement Tier` | Values: count of students, `[Avg Score]`, `[Pass Rate]`

Or **Heatmap** using a matrix visual with conditional formatting by student count.

---

### SECTION 14: BANKED vs NON-BANKED SCORES

```dax
Avg Score (Banked) =
CALCULATE(AVERAGE(fact_assessment[score]), fact_assessment[is_banked] = 1)

Avg Score (Non-Banked) =
CALCULATE(AVERAGE(fact_assessment[score]), fact_assessment[is_banked] = 0)

StdDev (Banked) =
CALCULATE(STDEV.P(fact_assessment[score]), fact_assessment[is_banked] = 1)

StdDev (Non-Banked) =
CALCULATE(STDEV.P(fact_assessment[score]), fact_assessment[is_banked] = 0)
```

**Visual**: **Clustered column chart** | Axis: `assessment_type` | Values: `[Avg Score (Banked)]`, `[Avg Score (Non-Banked)]`

---

### SECTION 15: TOP/BOTTOM PERFORMING STUDENTS

```dax
// Measures
Student Avg Score = AVERAGE(fact_assessment[score])
Assessments Taken = COUNTROWS(fact_assessment)
Student Total Clicks = SUM(fact_student_vle[sum_click])
```

**Visual 1 — Top 10**: **Table** (apply Top N filter = 10, by `[Student Avg Score]` descending)
- Columns: `id_student`, `gender`, `age_band`, `region`, `[Student Avg Score]`, `[Assessments Taken]`, `[Student Total Clicks]`
- Filters: `[Assessments Taken] >= 5`

**Visual 2 — Bottom 10**: Same table, Top N filter = 10, by `[Student Avg Score]` ascending.

---

### SECTION 16: SCORE PROGRESSION

```dax
// Measures identifying first/last assessment positions
First Assessment Avg =
CALCULATE(
    AVERAGE(fact_assessment[score]),
    // This requires a ranking approach in PowerBI
    // Use RANKX in a calculated column
)

// Calculated column in fact_assessment
Assessment Position =
VAR StudentType = fact_assessment[id_student] & "-" & RELATED(dim_assessment[assessment_type])
VAR Deadline = fact_assessment[date_submitted] // or use dim_assessment[date_deadline]
VAR RankInGroup =
    RANKX(
        FILTER(
            fact_assessment,
            fact_assessment[id_student] & "-" & RELATED(dim_assessment[assessment_type]) = StudentType
        ),
        RELATED(dim_assessment[date_deadline]),
        ,
        ASC,
        Dense
    )
VAR TotalInGroup =
    CALCULATE(
        COUNTROWS(fact_assessment),
        ALLEXCEPT(
            fact_assessment,
            fact_assessment[id_student],
            dim_assessment[assessment_type]
        )
    )
RETURN
    SWITCH(
        TRUE(),
        RankInGroup = 1, "First",
        RankInGroup = TotalInGroup, "Last",
        "Middle"
    )
```

**Visual**: **Clustered column chart** | Axis: `Assessment Position` | Legend: `assessment_type` | Values: `[Avg Score]`

---

### SECTION 17: GENDER GAP BY MODULE

```dax
Male Avg Score =
CALCULATE(AVERAGE(fact_assessment[score]), dim_student[gender] = "M")

Female Avg Score =
CALCULATE(AVERAGE(fact_assessment[score]), dim_student[gender] = "F")

Score Gap = [Male Avg Score] - [Female Avg Score]

Male Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[gender] = "M")

Female Pass Rate =
CALCULATE([Overall Pass Rate %], dim_student[gender] = "F")

Pass Rate Gap = [Male Pass Rate] - [Female Pass Rate]
```

**Visual**: **Table** | Rows: `code_module` | Columns: `[Male Avg Score]`, `[Female Avg Score]`, `[Score Gap]`, `[Pass Rate Gap]`

Add **arrow icons** (up/down) on the gap columns using conditional formatting.

---

### SECTION 18: REGISTRATION TIMING vs OUTCOME

```dax
// Calculated column in fact_registration
Registration Timing =
SWITCH(
    TRUE(),
    fact_registration[date_registration] < -100, "Very early (100+ days before)",
    fact_registration[date_registration] <= -50, "Early (50-100 days before)",
    fact_registration[date_registration] <= -1, "Near start (1-49 days before)",
    fact_registration[date_registration] >= 0, "Late/after start",
    "Unknown"
)
```

**Visual**: **Line & clustered column chart**
- Column: count per timing group
- Line: `[Pass Rate]` per timing group
- Axis: sorted `Registration Timing`

---

### SECTION 19: CREDIT LOAD vs SUCCESS

```dax
// Calculated column in dim_student
Credit Load =
SWITCH(
    TRUE(),
    dim_student[studied_credits] <= 30, "Part-time (<=30)",
    dim_student[studied_credits] <= 60, "Half-time (31-60)",
    dim_student[studied_credits] <= 120, "Full-time (61-120)",
    "Heavy load (120+)"
)
```

**Visual**: **Clustered column chart** | Axis: `Credit Load` (sorted) | Values: `[Pass Rate]`, `[Student Count]`

---

### SECTION 20: EXECUTIVE SUMMARY

Measures:
```dax
Total Students = COUNTROWS(dim_student)
Overall Pass Rate = [Overall Pass Rate %]
Overall Withdrawal Rate = [Overall Withdrawal Rate %]
Total Passed = [Total Passed]
Total Withdrawn = [Total Withdrawn]
Overall Avg Score = [Avg Assessment Score]
Overall Avg Clicks = [Avg Clicks Per Record]
Total Modules = DISTINCTCOUNT(dim_course[code_module])
Total Presentations = DISTINCTCOUNT(dim_course[code_presentation])
```

**Visual**: **6–8 Card visuals** in a row at the top of the dashboard.

---

## 5. Dashboard Page Layout (Recommended)

### Page 1: Executive Summary
- Top row: 8 KPI cards (students, pass rate, withdrawal rate, avg score, avg clicks, modules, presentations)
- Middle: Donut (final_result breakdown)
- Bottom left: Pass rate by gender (bar)
- Bottom right: Pass rate by age_band (bar)

### Page 2: Demographics Deep Dive
- Pass rate by education, IMD, disability, region (bar charts in a grid)
- Slicers: gender, age_band, final_result

### Page 3: VLE Engagement
- Weekly trend (line chart)
- Activity type breakdown (bar)
- Engagement vs outcome (clustered bar)
- Scatter: clicks vs score

### Page 4: Assessment Analysis
- Score by assessment type (bar)
- Exam scores by module (line with error)
- Submission timing impact (bar)
- Banked vs non-banked (clustered bar)

### Page 5: Withdrawal & At-Risk
- Withdrawal rate by age/gender (matrix heatmap)
- Withdrawal timing (pie)
- At-risk profile (table)
- Registration timing impact (bar)

### Page 6: Module Comparison
- Module performance table
- Scatter: VLE penetration vs pass rate
- Gender gap by module (table with arrows)

### Page 7: Student Segmentation
- RFM matrix (Score Tier x VLE Engagement)
- Top/Bottom 10 students (two tables)

### Page 8: Success Predictors
- Waterfall chart showing impact of each factor
- Factor impact table

---

## 6. Additional Enhancements

### Slicers (global filters)
- `code_module`
- `code_presentation`
- `gender`
- `age_band`
- `region`
- `final_result`

### Bookmarks
- "Reset All Filters" bookmark
- "Pass Only" bookmark

### Tooltips
- Custom report page tooltip for scatter chart (show detail student profile)

### Conditional Formatting
- Pass Rate: green (high) → red (low)
- Score Gap: green (male higher) → red (female higher)
- Withdrawal Rate: red (high) → green (low)
