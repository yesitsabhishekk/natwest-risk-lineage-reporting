WITH derived AS(
	SELECT
		loan_id,
        loan_amnt,
        int_rate,
        annual_inc,
        loan_status,
        ROUND(loan_amnt / NULLIF(annual_inc, 0), 3) AS debt_to_income_ratio,
        CASE
			WHEN int_rate < 8 THEN 'A'
            WHEN int_rate < 12 THEN 'B'
            WHEN int_rate < 16 THEN 'C'
            WHEN int_rate < 20 THEN 'D'
            ELSE 'E'
		END AS derived_grade_code,
		CASE
			WHEN loan_status IN ('Charged Off', 'Default', 'Does not meet the credit policy. Status:Charged Off') THEN 1
            WHEN loan_status IN ('Fully Paid', 'Does not meet the credit policy. Status:Fully Paid') THEN 0
            ELSE NULL
		END AS is_default
	FROM raw_loans_clean
),

ranked AS(
	SELECT
		d.*,
        RANK() OVER(PARTITION BY derived_grade_code ORDER BY debt_to_income_ratio DESC) AS dti_rank_in_grade,
        SUM(loan_amnt) OVER(PARTITION BY derived_grade_code) AS total_exposure_by_grade
	FROM derived AS d
)

SELECT 
	r.*,
    g.grade_label,
    g.risk_weight
FROM ranked AS r
LEFT JOIN risk_grade_mapping AS g
ON r.derived_grade_code = g.grade_code;

SELECT derived_grade_code, COUNT(*), MIN(debt_to_income_ratio), MAX(debt_to_income_ratio), ROUND(AVG(debt_to_income_ratio),3)
FROM (
	SELECT
		loan_id,
        loan_amnt,
        int_rate,
        annual_inc,
        loan_status,
        ROUND(loan_amnt / NULLIF(annual_inc, 0), 3) AS debt_to_income_ratio,
        CASE
			WHEN int_rate < 8 THEN 'A'
            WHEN int_rate < 12 THEN 'B'
            WHEN int_rate < 16 THEN 'C'
            WHEN int_rate < 20 THEN 'D'
            ELSE 'E'
		END AS derived_grade_code,
		CASE
			WHEN loan_status IN ('Charged Off', 'Default', 'Does not meet the credit policy. Status:Charged Off') THEN 1
            WHEN loan_status IN ('Fully Paid', 'Does not meet the credit policy. Status:Fully Paid') THEN 0
            ELSE NULL
		END AS is_default
	FROM raw_loans_clean
) t
GROUP BY derived_grade_code
ORDER BY derived_grade_code;

SELECT
	loan_id,
    loan_amnt,
    annual_inc,
	ROUND(loan_amnt / NULLIF(annual_inc, 0), 3) AS debt_to_income_ratio
FROM raw_loans_clean
WHERE ROUND(loan_amnt / NULLIF(annual_inc, 0), 3) = 0
LIMIT 10;

CREATE VIEW ranked_view AS
WITH derived AS (
  SELECT
    loan_id,
    loan_amnt,
    int_rate,
    annual_inc,
    issue_date,
    loan_status,
    ROUND(loan_amnt / NULLIF(annual_inc, 0), 3) AS debt_to_income_ratio,
    CASE
      WHEN int_rate < 8 THEN 'A'
      WHEN int_rate < 12 THEN 'B'
      WHEN int_rate < 16 THEN 'C'
      WHEN int_rate < 20 THEN 'D'
      ELSE 'E'
    END AS derived_grade_code,
    CASE
      WHEN loan_status IN ('Charged Off', 'Default', 'Does not meet the credit policy. Status:Charged Off') THEN 1
      WHEN loan_status IN ('Fully Paid', 'Does not meet the credit policy. Status:Fully Paid') THEN 0
      ELSE NULL
    END AS is_default
  FROM raw_loans_clean
),
ranked AS (
  SELECT
	d.*,
    RANK() OVER (PARTITION BY derived_grade_code ORDER BY debt_to_income_ratio DESC) AS dti_rank_in_grade,
    SUM(loan_amnt) OVER (PARTITION BY derived_grade_code) AS total_exposure_by_grade
  FROM derived d
)
SELECT
	r.*,
    g.grade_label,
    g.risk_weight
FROM ranked r
LEFT JOIN risk_grade_mapping g ON r.derived_grade_code = g.grade_code;

SELECT *
FROM ranked_view
LIMIT 10;