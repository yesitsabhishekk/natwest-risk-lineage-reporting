#Data Quality and Process Notes

##Risk Grade Mapping Table
- Source data provides interest rate but no direct "risk weight" or business friendly risk label.
- Created a custom reference table (`risk_grade_mapping.csv`) mapping 5 risk grades (A-E) to a human readable label and a risk weight multiplier.
- Risk weights use even 0.5 increments for a simple, explainable scale.
- This table simulates a second, independent data scource, enabling a genuine join-based lineage story rather than single-table pipeline.

##Import Issues
- Inital table data import wizard failed on columns like `il_until`, `mths_since_recent_inq` - blank cells couldn't cast to integer type the wizard auto detected.
- Fixed by importing all columns as TEXT first (staging layer), avoiding row loss entirely.
- Wizard's row-by-row import was too slow for 2.26M rows (ran 20+ hours without completing) - switched to `LOAD DATA LOCAL INFILE` via MySQL command line client, completed in 1 minute.
- Hit `local_infile` permission error (Error 2068), resolved via `SET GLOBAL local_infile = 1` plus `--local-infile=1` flag on the command-line client connection.

##Deisgn Decision
- Used a raw/staging (VARCHAR) - clean/curated (typed) table pattern to gurantee zero row loss during import, mirroring real ETL pipeline practice.

##Data Quality Findings
- raw_loans_clean has ~2,260,666 rows after cleaning (2,260,668 loaded, 2 removed as outliers - see below).
- Null rates: `loan_amnt`, `int_rate`, `loan_status`, `issue_date` all 0% null. `annual_inc` had 4 nulls (0.0002%) before outlier removal, all tied to loans with status "Does not meet the credit policy. Status:Fully Paid".
- Descriptive stats: `loan_amnt` avg 15,046.93 / median 12,900.00 / min 500 / max 40,000. `int_rate` avg 13.09 / median 12.62 / min 5.31 / max 30.99. `annual_inc` avg 77,992.43 / median 65,000.00 (pre-cleanup) - mean vs. median gap indicates right-skew from a few high-income outliers.
- Loan issue dates range from 2007-06-01 to 2018-12-01 (~11.5 years of data).
- Initial 3-standard-deviation outlier test on `annual_inc` flagged 1000+ rows, including ordinary incomes ($450K-$700K) - the stddev itself was inflated by 1-2 extreme values, making this method unreliable here.
- Investigated top `annual_inc` values using income-to-loan-amount ratio instead of income alone. Top 2 rows ($110M and $61M against loans of $30K and $10K - ratios of 3,667x and 6,100x) were implausible for a personal lending platform and identified as likely data entry errors.
- Remaining high-income rows ($9M-$11M) showed more plausible ratios and were retained rather than assumed erroneous.
- Deleted the 2 confirmed-erroneous rows from `raw_loans_clean` (negligible impact - 2 rows out of ~2.26M).

##Default Classification 
- Built `is_default` via CASE WHEN across all 9 `loan_status` values: `Charged Off`/`Default`/`Does not meet the credit policy. Status:Charged Off` -> 1, `Fully Paid`/`Does not meet the credit policy. Status:Fully Paid` -> 0, remaining 4 statuses (`Current`, `Late (31-120 days)`, `Late (16-30 days)`, `In Grace Period`) -> NULL (unresolved outcome, excluded from default modeling since final outcome not yet known).
- Verified full 2,260,666-row transformation completes via `ranked_view` using CTEs, CASE-based grade bucketing, and window functions (RANK, SUM OVER PARTITION).

##Validation
- DTI ratio confirmed to vary meaningfully across grades: avg DTI flat across grades A-D (0.542-0.555) but jumps to 0.844 for grade E - the riskiest interest-rate bucket also shows the highest average debt-to-income ratio, an independent signal supporting the grade design.
- MIN(debt_to_income_ratio) = 0.000 across all grades traced to legitimate high-income/small-loan combinations (e.g., $9M income vs. $3,600 loan) rounding to zero at 3 decimal places - not a data quality issue.

##Aggregation Results
- Built `grade_summary` table from `ranked_view` - default rate rises monotonically from 5.86% (Grade A) to 40.71% (Grade E), a ~7x spread, validating the interest-rate-based grading approach.
- Verified `num_loans` = `num_defaulted` + `num_paid` + `num_unresolved` for all 5 grades - no rows lost or double-counted in aggregation.

##Chi-Square Test
- Ran CHISQ.TEST() in Excel comparing actual vs. expected defaulted/paid counts across the 5 grades.
- Result: p < 0.0001 - reject the null hypothesis of independence. Confirms the relationship between grade and default outcome is statistically significant, not due to chance.
