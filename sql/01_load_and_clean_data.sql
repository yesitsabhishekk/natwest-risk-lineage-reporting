CREATE DATABASE natwest_risk;
USE natwest_risk;

CREATE TABLE raw_loans(
  id TEXT,
  loan_amnt TEXT,
  int_rate TEXT,
  annual_inc TEXT,
  loan_status TEXT,
  issue_d TEXT
);


CREATE TABLE raw_loans_clean(
loan_id INT AUTO_INCREMENT PRIMARY KEY,
loan_amnt DECIMAL(10,2),
int_rate DECIMAL(10,2),
annual_inc DECIMAL(15,2),
loan_status VARCHAR(255),
issue_date  DATE
);

INSERT INTO raw_loans_clean (loan_amnt, int_rate, annual_inc, loan_status, issue_date)
SELECT
	CAST(NULLIF(loan_amnt, '') AS DECIMAL(10,2)),
    CAST(NULLIF(int_rate, '') AS DECIMAL(10,2)),
    CAST(NULLIF(annual_inc, '') AS DECIMAL(15,2)),
    loan_status,
    str_to_date(CONCAT('01-', issue_d), '%d-%b-%Y')
FROM raw_loans
WHERE loan_amnt IS NOT NULL AND loan_amnt != '';

