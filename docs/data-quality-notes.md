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


