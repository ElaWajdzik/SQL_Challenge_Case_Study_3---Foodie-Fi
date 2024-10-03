------------------------------
--A. Customer Journey--
------------------------------

--Author: Ela Wajdzik
--Date: 27.09.2024
--Tool used: Microsoft SQL Server


--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
--Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

-- generate a random list of 8 unique customer IDs.

WITH customers AS (
	SELECT DISTINCT customer_id
	FROM subscriptions
)

SELECT 
	TOP 8 * 
FROM customers
ORDER BY NEWID();

-- select list of customer IDs (901, 470, 996, 918, 354, 168, 12, 432).

-- check how customers changed their plans over time based on popularity

WITH plan_change_histories AS (
SELECT 
	customer_id,
	STRING_AGG (plan_id, ',') WITHIN GROUP (ORDER BY start_date ASC) AS plan_change_history -- concatenate the information about all plans for each customer in chronological order (by start_date)
FROM subscriptions
GROUP BY customer_id
)

SELECT 
	plan_change_history,
	COUNT(*) AS number_of_customers
FROM plan_change_histories
GROUP BY plan_change_history
ORDER BY number_of_customers DESC;

--Based on the data, we can observe that:
--		Every customer starts with a free trial.
--		Customers either churn (cancel their subscription) or maintain an active subscription.
--		No customer downgraded from the pro plan to the basic plan.

SELECT 
	s.customer_id,
	s.plan_id,
	p.plan_name,
	s.start_date
FROM subscriptions s
INNER JOIN plans p
ON s.plan_id = p.plan_id
WHERE s.customer_id IN (901, 470,  996,  918, 354, 168, 12, 432);
