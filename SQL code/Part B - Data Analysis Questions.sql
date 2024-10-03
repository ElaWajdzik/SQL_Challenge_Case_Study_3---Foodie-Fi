------------------------------
--B. Data Analysis Questions--
------------------------------

--Author: Ela Wajdzik
--Date: 27.09.2024 (update 2.10.2024)
--Tool used: Microsoft SQL Server


-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT 
	DATETRUNC(month, start_date) AS start_of_month, -- truncated to the start tof the month
	COUNT(*) AS number_of_customers
FROM subscriptions
WHERE plan_id = 0 -- select only records related to the trial plan
GROUP BY DATETRUNC(month, start_date)
ORDER BY start_of_month; -- use the alias for the column: DATETRUNC(month, start_date)


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT 
	YEAR(s.start_date) AS start_year,
	p.plan_name,
	COUNT(*) AS number_of_plans
FROM subscriptions s
INNER JOIN plans p
ON p.plan_id = s.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY YEAR(s.start_date), p.plan_name;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

DECLARE @n_customers_churn INT; --declare the local variable 
DECLARE @n_customers INT;

SET @n_customers_churn = 
(SELECT
	COUNT(*)
FROM subscriptions
WHERE plan_id = 4);

SET @n_customers =
(SELECT COUNT(DISTINCT customer_id)
FROM subscriptions);

-- print the results
PRINT 'Number of customers who churned: ' + CAST(@n_customers_churn AS VARCHAR);
PRINT 'Percentage of customers who have churned: ' + CAST(CAST(@n_customers_churn * 100.0 / @n_customers AS NUMERIC (4,1)) AS VARCHAR) +'%';


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

-- How many customers have a plan_change_history = 0,4

WITH plan_change_histories AS (
SELECT 
	customer_id,
	STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC) AS plan_change_history
FROM subscriptions
GROUP BY customer_id
)

SELECT 
	plan_change_history,
	COUNT(*) AS number_of_customers,

	-- use a subquery to calculate the total number of customers
	CAST(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS NUMERIC (3,0)) AS percent_of_customers
FROM plan_change_histories
--WHERE plan_change_history = '0,4' --filter to show only the relevent case (customers who churned immediately after the trial)
GROUP BY plan_change_history
ORDER BY number_of_customers DESC;

-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH plan_change_histories AS (
SELECT 
	customer_id,
	STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC) AS plan_change_history,
	SUBSTRING(STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC), 3, 1) AS plan_after_trial --select the plan_id for the plan after the trial
FROM subscriptions
GROUP BY customer_id
)

SELECT 
	p.plan_name AS plan_name_after_trial,
	COUNT(*) AS number_of_customers,
	CAST(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS NUMERIC (4,1)) AS percent_of_customers
FROM plan_change_histories h
INNER JOIN plans p --join the plans table to display the names of the plans
ON p.plan_id = h.plan_after_trial
GROUP BY p.plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH plan_change_histories AS (
SELECT 
	customer_id,
	--STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC) plan_change_history,
	SUBSTRING(STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date DESC), 1, 1) AS plan_end_2020 --select the last plan_id in 2020
FROM subscriptions
WHERE YEAR(start_date) < 2021 --filter the data to include only entries before the year 2021
GROUP BY customer_id
)

SELECT 
	p.plan_name AS plan_name_end_2020,
	COUNT(*) AS number_of_customers,
	CAST(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE YEAR(start_date) < 2021) AS NUMERIC (4,1)) AS percent_of_customers
FROM plan_change_histories h
INNER JOIN plans p
ON p.plan_id = h.plan_end_2020
GROUP BY p.plan_name;

-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT 
	COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions
WHERE YEAR(start_date) < 2021
AND plan_id = 3;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH customers_with_annual_plan AS ( -- for each customer on annual plan, select the start date of this plan
	SELECT 
		customer_id,
		MIN(start_date) AS start_annual_plan 
	FROM subscriptions
	WHERE plan_id = 3
	GROUP BY customer_id),

customers_start_date AS(  -- for each customer, select the start date of the trial
	SELECT 
		customer_id,
		MIN(start_date) AS start_trial
	FROM subscriptions
	WHERE plan_id = 0
	GROUP BY customer_id
	)

SELECT 
	AVG(DATEDIFF(day, start_trial, start_annual_plan)) AS avg_days_to_annual_plan --calculate the differenc in days between the strat of the trial and the start of the annual plan
FROM customers_with_annual_plan ap
LEFT JOIN customers_start_date sd -- use a left join because we need information only for customers who upgraded to the annual plan
ON ap.customer_id = sd.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH customers_with_annual_plan AS ( -- for each customer on annual plan, select the start date of this plan
	SELECT 
		customer_id,
		MIN(start_date) AS start_annual_plan
	FROM subscriptions
	WHERE plan_id = 3
	GROUP BY customer_id),

customers_start_date AS( -- for each customer, select the start date of the trial
	SELECT 
		customer_id,
		MIN(start_date) AS start_trial
	FROM subscriptions
	WHERE plan_id = 0
	GROUP BY customer_id
	),

customer_with_split_groups AS (
	SELECT 
		ap.customer_id,
		DATEDIFF(day, sd.start_trial, ap.start_annual_plan) AS days_to_annual_plan,
		FLOOR(DATEDIFF(day, sd.start_trial, ap.start_annual_plan)/30.0) AS group_id 
	FROM customers_with_annual_plan ap
	LEFT JOIN customers_start_date sd  -- use a left join because we need information only for customers who upgraded to the annual plan
	ON ap.customer_id = sd.customer_id)

SELECT 
	CONCAT(
		CASE group_id 
			WHEN 0 THEN 0
			ELSE (group_id  * 30) +1
		END,
		' - ', 
		(group_id +1) * 30) AS group_name_days,
	COUNT(*) AS number_of_customers
FROM customer_with_split_groups
GROUP BY group_id;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- How many customer downgraded from plan_id=2 to plan_id=1

WITH plan_change_histories AS (
SELECT 
	customer_id,
	STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC) AS plan_change_history
FROM subscriptions
WHERE YEAR(start_date) < 2021
GROUP BY customer_id
)

SELECT 
	CHARINDEX('2,1', plan_change_history) AS downgraded_from_2_to_1,
	COUNT(*) As number_of_customers
FROM plan_change_histories
WHERE CHARINDEX('2,1', plan_change_history) != 0
GROUP BY CHARINDEX('2,1', plan_change_history);