SELECT
	COUNT(*) AS total_rows
FROM raw_loans_clean;

DESCRIBE raw_loans_clean;

DESCRIBE risk_grade_mapping;

SELECT
	SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) AS null_loan_amnt,
    SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END) AS null_int_rate,
    SUM(CASE WHEN annual_inc IS NULL THEN 1 ELSE 0 END) AS null_annual_inc,
	SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS null_loan_status,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) AS null_issue_date
FROM raw_loans_clean;

SELECT
	ROUND(SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_loan_amnt_pct,
    ROUND(SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_int_rate_pct,
    ROUND(SUM(CASE WHEN annual_inc IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_annual_inc_pct,
    ROUND(SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_loan_status_pct,
    ROUND(SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS null_issue_date_pct
FROM raw_loans_clean;

SELECT *
FROM raw_loans_clean
WHERE annual_inc IS NULL;

SELECT 
	loan_status,
    COUNT(*) AS count_per_status
FROM raw_loans_clean
GROUP BY loan_status
ORDER BY count_per_status DESC;

SELECT
	ROUND(AVG(loan_amnt),2) AS avg_loan_amnt,
    MIN(loan_amnt) AS min_loan_amnt,
    MAX(loan_amnt) AS max_loan_amnt,
    ROUND(STDDEV(loan_amnt),2) AS stddev_loan_amnt,
    ROUND(AVG(int_rate),2) AS avg_int_rate,
    MIN(int_rate) AS min_int_rate,
    MAX(int_rate) AS max_int_rate,
    ROUND(STDDEV(int_rate),2) AS stddev_int_rate,
    ROUND(AVG(annual_inc),2) AS avg_annual_inc,
    MIN(annual_inc) AS min_annual_inc,
    MAX(annual_inc) AS max_annual_inc,
    ROUND(STDDEV(annual_inc),2) AS stddev_annual_inc
FROM raw_loans_clean;

SELECT
	'loan_amnt' AS metric,
    ROUND(AVG(loan_amnt),2) AS median_value
FROM (
	SELECT
		loan_amnt,
        ROW_NUMBER() OVER(ORDER BY loan_amnt) AS row_num,
        COUNT(*) OVER() AS total_rows
	FROM raw_loans_clean
) AS ranked
WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
UNION ALL
SELECT
	'int_rate' AS metric,
    ROUND(AVG(int_rate),2) AS median_value
FROM (
	SELECT
		int_rate,
        ROW_NUMBER() OVER(ORDER BY int_rate) AS row_num,
        COUNT(*) OVER() AS total_rows
	FROM raw_loans_clean
) AS ranked
WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
UNION ALL
SELECT
	'annual_inc' AS metric,
    ROUND(AVG(annual_inc),2) AS median_value
FROM (
	SELECT
		annual_inc,
        ROW_NUMBER() OVER(ORDER BY annual_inc) AS row_num,
        COUNT(*) OVER() AS total_rows
	FROM raw_loans_clean
) AS ranked
WHERE row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2));

SELECT
	MIN(issue_date) AS earliest_loan,
    MAX(issue_date) AS latest_loan
FROM raw_loans_clean;

SELECT 
	loan_id,
    annual_inc
FROM raw_loans_clean
ORDER BY annual_inc DESC
LIMIT 10;

SELECT 
	loan_id,
    annual_inc
FROM raw_loans_clean
WHERE annual_inc > (
	SELECT 
		AVG(annual_inc) + 3 * STDDEV(annual_inc) 
	FROM raw_loans_clean
);

SELECT
	loan_id,
    loan_amnt,
    annual_inc,
    loan_status
FROM raw_loans_clean
WHERE annual_inc > 20000000;

DELETE FROM raw_loans_clean
WHERE annual_inc > 20000000;

SET SQL_SAFE_UPDATES = 0;

SELECT 
	COUNT(*) 
FROM raw_loans_clean
WHERE annual_inc > 20000000;



