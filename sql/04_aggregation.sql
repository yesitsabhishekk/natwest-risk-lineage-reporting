CREATE TABLE grade_summary AS
	SELECT
		derived_grade_code,
        grade_label,
        risk_weight,
        COUNT(*) AS num_loans,
        SUM(loan_amnt) AS total_exposure,
        ROUND(SUM(loan_amnt * risk_weight), 2) AS weighted_exposure,
        SUM(CASE WHEN is_default = 1 THEN 1 ELSE 0 END) AS num_defaulted,
		SUM(CASE WHEN is_default = 0 THEN 1 ELSE 0 END) AS num_paid,
		SUM(CASE WHEN is_default IS NULL THEN 1 ELSE 0 END) AS num_unresolved,
		ROUND(
			SUM(CASE WHEN is_default = 1 THEN 1 ELSE 0 END) * 100.0
			/ NULLIF(SUM(CASE WHEN is_default IN (0,1) THEN 1 ELSE 0 END), 0)
			, 2) AS default_rate_pct
FROM ranked_view
GROUP BY derived_grade_code, grade_label, risk_weight
ORDER BY derived_grade_code;

SELECT *
FROM grade_summary;

SELECT 
	derived_grade_code,
	num_loans,
	(num_defaulted + num_paid + num_unresolved) AS check_total
FROM grade_summary;