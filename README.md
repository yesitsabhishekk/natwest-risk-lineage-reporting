# natwest-risk-lineage-reporting

## Business Problem

- A regulator or internal auditor asks:

> "Where did this credit risk exposure number in the report come from,
> and can you prove every transformation it went through?"

This project builds a simulated BCBS 239-style risk data aggregation and traceability workflow that answers that question through an auditable SQL pipeline, source-to-target mapping, data lineage documentation, datadictionary, statistical validation, and risk reporting output.
The project is designed as a banking risk-data / regulatory-reporting simulation rather than a generic SQL dashboard project.

## Data Source

### Lending Club loan data

The primary source is the public **Lending Club loan dataset(2007--2018)**, containing loan-level information such as loan amount, interest rate, annual income, loan status, and issue date. The dataset provides a sufficiently large loan population to demonstrate data-quality controls, SQL transformation, aggregation, and risk reporting at scale.

The project uses a staging-to-curated pattern:

-   `raw_loans` --- staging table where source fields are initially loaded as text.
-   `raw_loans_clean` --- typed and cleaned loan-level table used for downstream transformations.
-   `ranked_view` --- derived and enriched reporting layer.
-   `grade_summary` --- final grade-level aggregation consumed by Excel and Power BI.

The staging approach was used to avoid import-time type-casting failures and preserve source rows during ingestion. The final cleaned population contains approximately **2.26 million loans**. Two extreme annual-income records were removed after investigation because their income-to-loan ratios were implausible; the remaining high-income observations were retained.

### Custom risk-grade reference data

A custom `risk_grade_mapping.csv` reference table was created with:

-   `grade_code`
-   `grade_label`
-   `risk_weight`

The mapping provides business-friendly risk labels and a risk-weight multiplier for Grades A--E. It also creates a second independent reference source, allowing the project to demonstrate an actual join and a traceable multi-source lineage rather than relying on a single-table transformation.

## Methods Used

### Data ingestion and quality

-   MySQL staging and curated-table pattern
-   Text-first ingestion followed by explicit type casting
-   Null-rate and data-type profiling
-   Descriptive statistics for loan amount, interest rate, and annual income
-   Investigation of extreme income observations using income-to-loan ratios
-   Loan-status classification into defaulted, paid, and unresolved outcomes

### Advanced SQL

-   Common Table Expressions (CTEs) to stage transformations
-   `CASE WHEN` logic for risk-grade derivation from interest-rate bands
-   Derived `debt_to_income_ratio`
-   Window functions:
    -   `RANK() OVER (PARTITION BY ...)`
    -   `SUM() OVER (PARTITION BY ...)`
-   Join to the independent `risk_grade_mapping` reference table
-   `GROUP BY` aggregation into `grade_summary`
-   Risk-weighted exposure calculation
-   Reconciliation check confirming: `num_loans = num_defaulted + num_paid + num_unresolved`

### Statistical validation

-   Segmented default-rate analysis by risk grade
-   Exposure analysis by risk grade
-   Chi-square test of independence between risk grade and resolved loan outcome
-   95% confidence interval for the highest-risk grade's observed default rate

### Documentation and reporting

-   Source-to-target mapping (STM)
-   Data lineage diagram
-   Data dictionary
-   Power BI risk reporting dashboard
-   DAX measures for portfolio-level and loan-outcome metrics
-   AI-assisted emerging-risk narrative generated from the validated aggregated output

## Key Findings

### Portfolio

The final aggregated portfolio contains approximately **2.26 million loans** with **\$34.02 billion** of nominal exposure and **\$46.92 billion** of risk-weighted exposure. The overall observed default rate is **20.09%**, calculated using resolved loans only. **954.28K loans (42.2% of the portfolio) remain unresolved** and are therefore excluded from the observed default-rate denominator.

### Risk-grade behaviour

Observed default rates increase monotonically across the five risk grades: 
Grade E has the highest observed default rate at **40.71%**, approximately **7× Grade A's 5.86%**.

### Statistical validation

The chi-square test comparing defaulted and paid counts across Grades
A--E produced:

-   **Chi-square statistic:** 81,680.37
-   **Degrees of freedom:** 4
-   **p-value:** \< 0.0001

The result provides strong statistical evidence of an association between risk grade and resolved loan outcome in this dataset.

For Grade E, the observed default rate is **40.71%** with an approximate **95% confidence interval of 40.42%--41.01%**.

### Exposure and risk weighting

Grade E represents approximately **9.6% of nominal exposure (\$3.28B of \$34.02B)** but approximately **17.5% of risk-weighted exposure (\$8.20B of \$46.92B)**.

Grades C, D, and E together account for approximately **74% of total risk-weighted exposure**. Grade C has the largest individual risk-weighted exposure at **\$14.74B**.

### Loan outcomes and interpretation

The loan-outcome composition shows that unresolved loans are material across the portfolio. Grade A, for example, has **47.7% unresolved loans**, while Grade E has **42.5% unresolved loans**. Consequently, the observed default rates should be interpreted as rates among resolved loans rather than final default rates for the entire loan population.

The AI-assisted risk narrative therefore uses the aggregated, validated `grade_summary` output as its input and does not alter the underlying calculations.

## AI-Assisted Emerging Risk Narrative

- Observed default rates rise steadily with risk grade, from **5.86% in Grade A to 40.71% in Grade E (approximately 7×)**, with the chi-square test indicating a statistically significant association between risk grade and loan outcome (**p \< 0.0001**). Grade E holds only **9.6% of nominal exposure (\$3.28bn of \$34.02bn)** but accounts for **17.5% of risk-weighted exposure (\$8.20bn of \$46.92bn)**, while Grades C, D and E together carry approximately **74% of risk-weighted exposure**.

- **Recommended action:** prioritise enhanced monitoring of Grades D and E, where observed default rates exceed 30%, while reviewing concentration in Grade C, which has the largest risk-weighted exposure at **\$14.74bn**. These default rates should be treated as provisional because **42.2% of loans (954K) remain unresolved** and are excluded from the observed default-rate denominator; notably, unresolved loans represent **47.7% of Grade A loans**.

The narrative is an AI-assisted reporting layer: the model receives structured, already-validated grade-level statistics and generates plain-English commentary. It does not participate in source-data transformation or risk calculation.

## Artifacts

-   [Source-to-Target Mapping](excel/source_to_target_mapping.xlsx)
-   [Data Lineage Diagram](docs/lineage-diagram.png)
-   [Data Dictionary](excel/data_dictionary.xlsx)
-   [Data Quality and Process Notes](docs/data-quality-notes.md)
-   [AI-Assisted Emerging Risk Narrative](docs/ai-narrative-example.md)
-   [Chi-Square Validation](excel/chi_square_test.xlsx)
-   [Aggregated Grade Summary](data/processed/grade_summary.csv)
-   [Power BI Dashboard](dashboard/natwest_risk_report.pbix)
-   [Dashboard Preview](dashboard/natwest_risk_report.png)
-   [Dashboard Preview Pdf](dashboard/natwest_risk_report.pdf)
-   [SQL --- Load and Clean](sql/01_load_and_clean_data.sql)
-   [SQL --- Data Profiling](sql/02_data_profiling.sql)
-   [SQL --- Transformation Pipeline](sql/03_transform_pipeline.sql)
-   [SQL --- Aggregation](sql/04_aggregation.sql)

## How to Reproduce

### 1. Set up the project structure

``` text
natwest-risk-lineage-reporting/
├── data/
│   ├── raw/
│   │   ├── loan.csv
│   │   └── risk_grade_mapping.csv
│   └── processed/
│       └── grade_summary.csv
├── sql/
│   ├── 01_load_and_clean_data.sql
│   ├── 02_data_profiling.sql
│   ├── 03_transform_pipeline.sql
│   └── 04_aggregation.sql
├── excel/
│   ├── source_to_target_mapping.xlsx
│   └── chi_square_test.xlsx
├── docs/
│   ├── data-quality-notes.md
│   ├── ai-narrative-example.md
│   └── lineage-diagram.png
├── dashboard/
│   ├── natwest_risk_report.pbix
│   └── natwest_risk_report.png
│   └── natwest_risk_report.pdf
└── README.md
```

### 2. Load the source data into MySQL

Create the database and staging table using:

``` sql
CREATE DATABASE natwest_risk;
USE natwest_risk;
```

Load the Lending Club source data into `raw_loans` and the custom reference table into `risk_grade_mapping`.

The project uses a staging layer with source fields loaded as text, followed by explicit casting into `raw_loans_clean`. This avoids source-import type conflicts and makes the ingestion step auditable.

### 3. Run the SQL pipeline

Run the SQL scripts in this order:

``` text
01_load_and_clean_data.sql
        ↓
02_data_profiling.sql
        ↓
03_transform_pipeline.sql
        ↓
04_aggregation.sql
```

The transformation pipeline derives the risk grade, calculates the debt-to-income ratio, applies window functions, and joins the risk-grade reference data. The aggregation script creates the five-row `grade_summary` reporting dataset.

### 4. Export the reporting dataset

Export the resulting `grade_summary` table from MySQL to:

``` text
data/processed/grade_summary.csv
```

This small aggregated dataset is used for downstream Excel validation and Power BI reporting rather than exporting the millions of loan-level records.

### 5. Perform statistical validation

Use the aggregated grade-level data to construct the defaulted/paid contingency table in Excel.

Calculate expected counts using:

``` text
Expected count =
(Row total × Column total) / Grand total
```

Then calculate the chi-square p-value using:

``` excel
=CHISQ.TEST(actual_range, expected_range)
```

For the highest-risk Grade E, calculate the approximate 95% confidence interval using the observed default proportion, standard error, and 1.96 multiplier.

### 6. Build the reporting layer

Import:

``` text
data/processed/grade_summary.csv
```

into Power BI and reproduce the portfolio KPI cards and three analytical views:

1.  Observed Default Rate by Risk Grade
2.  Loan Outcome Composition by Risk Grade
3.  Nominal vs Risk-Weighted Exposure

The dashboard uses measures for observed default rate and loan-outcome shares rather than averaging pre-calculated grade percentages.

### 7. Generate the AI narrative

Provide the validated `grade_summary` output to an LLM using the project's AI narrative prompt. Save the prompt and generated commentary in:

``` text
docs/ai-narrative-example.md
```

The AI layer is downstream of the validated aggregation and is intended to accelerate risk-committee commentary, not to calculate or modify risk metrics.

## Project Outcome

The completed workflow connects **source data → staging → cleaning → transformation → risk-grade enrichment → aggregation → statistical validation → reporting → AI-assisted commentary**.

The resulting artifacts provide both the analytical output and the traceability documentation needed to explain how a reported risk exposure number was produced and how its underlying transformations were validated.
