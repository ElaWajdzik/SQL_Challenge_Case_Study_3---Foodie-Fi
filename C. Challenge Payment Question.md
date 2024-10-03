# <p align="center"> Case Study #3: 🥑 Foodie-Fi
 
## <p align="center"> C. Challenge Payment Question

The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

### Steps:

1. Create a new empty table ```customer_payments``` based on the provided example. 

````sql
DROP TABLE IF EXISTS customer_payments;
CREATE TABLE customer_payments (
	payment_id INT IDENTITY(1,1) PRIMARY KEY,
	customer_id INT NOT NULL,
	plan_id INT NOT NULL,
	plan_name VARCHAR(20) NOT NULL,
	payment_date DATE NOT NULL,
	amount NUMERIC (5,2) NOT NULL,
	payment_order INT NOT NULL);
````

2. Create a new supporting table ```n_month``` containing the numbers 1 to 12 (to represent the 12 months of the year).

````sql
DROP TABLE IF EXISTS n_month;
CREATE TABLE n_month (
  n INT
);

INSERT INTO n_month
    (n)
VALUES
    (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);
````

3. Create a common table expresion (CTE) with several transformations of existing tables and insert this data into the ```customer_payments``` table.

    - Create the temporary table contains a history of plans and plan changes for each customer using the ```STRING_AGG()``` function.
    - Create the temporary table with the history is split into rows for each plan, maintaining the order of plans, using the ```CROSS APPLY STRING_SPLIT()``` function.
    - Add information about the previous plan, the start date of the previous plan, the next plan and current plan, using the ```SUBSTRING()``` function multiple times.
    - Add information about any reduced price if the customer upgraded their plan during an active billing period, using the ```CASE``` AND ```DATEADD()``` functions.
    - Add the date of the last payment for the current plan, using the ```DATEADD()``` functions.
    - Split data into rows corresponding to recurring payments using the ```n_month``` table.
    - In last step calcutale the reduced price only for the first payment in the subscription and filter out any duplicate payments from old and new plans. 


````sql
WITH customers_plan_history AS (

-- the table contains a history of plans and plan changes for each customer
	SELECT 
		customer_id,
		STRING_AGG(plan_id, ',') AS plan_history,
		STRING_AGG(start_date, '') + '2021-01-01' AS change_time_history
	FROM subscriptions
	WHERE plan_id != 0
	--AND customer_id = 19 --IN (7, 16, 19, 996, 873)
	GROUP BY customer_id),

customers_with_plans AS (

-- the history is split into rows for each plan, with the order of plans
	SELECT 
		customer_id,
		plan_history,
		change_time_history,
		value AS plan_id,
		CHARINDEX(value, REPLACE(plan_history, ',', '')) AS plan_order
	FROM customers_plan_history
		CROSS APPLY STRING_SPLIT(plan_history, ',')),

customers_with_plans_and_date AS(

-- add information about the previous plan, the start date of the previous plan, and the next and current plan
	SELECT 
		customer_id,
		plan_order,
		plan_id,
		CASE plan_order
			WHEN 1 THEN NULL
			ELSE SUBSTRING(REPLACE(plan_history, ',', ''), plan_order - 1, 1) 
		END AS before_plan_id,
		plan_history,
		SUBSTRING(change_time_history, (plan_order-1)*10 +1, 10) AS plan_start,
		SUBSTRING(change_time_history, (plan_order)*10 +1, 10) AS next_plan_start,
		CASE plan_order 
			WHEN 1 THEN NULL
			ELSE SUBSTRING(change_time_history, (plan_order-2)*10 +1, 10)
		END AS before_plan_start
	FROM customers_with_plans),

customers_with_plans_and_date_1 AS (

-- add information about any reduced price if the customer upgraded their plan during an active billing period
-- include the date of the last payment for the current plan
	SELECT
		*,
		CASE 
			WHEN (
					CASE 
						WHEN before_plan_id IN (1,2) THEN CAST(DATEADD(month, MONTH(plan_start) - MONTH(before_plan_start), before_plan_start) AS DATE)
						WHEN before_plan_id = 3 THEN CAST(DATEADD(year, YEAR(plan_start) - YEAR(before_plan_start), before_plan_start) AS DATE)
						ELSE plan_start
					END) = plan_start THEN 0
			ELSE 1
		END AS price_reduced,
		CASE 
			WHEN plan_id IN (1,2) THEN CAST(DATEADD(month, MONTH(next_plan_start) - MONTH(plan_start), plan_start) AS DATE)
			WHEN plan_id = 3 THEN CAST(DATEADD(year, YEAR(next_plan_start) - YEAR(plan_start), plan_start) AS DATE)
			ELSE NULL
		END AS last_payment_actual_plan
	FROM customers_with_plans_and_date),

customer_payments_CTE AS (

-- split data into rows corresponding to recurring payments
	SELECT 
		*,
		CASE plan_id
			WHEN 3 THEN p.plan_start
			ELSE CAST(DATEADD(month, m.n - MONTH(p.plan_start), plan_start) AS DATE)
		END AS paymant_date
	FROM customers_with_plans_and_date_1 p
	LEFT JOIN n_month m
	ON MONTH(p.plan_start) <= m.n AND MONTH(p.last_payment_actual_plan) >= m.n
	WHERE plan_id !=4)



-- ensure the final table contains all required columns
INSERT INTO customer_payments(customer_id, plan_id, plan_name, payment_date, amount, payment_order)
SELECT 
	cp.customer_id,
	cp.plan_id,
	p.plan_name,
	cp.paymant_date,
	p.price -
	CAST(CASE
		WHEN cp.paymant_date = cp.plan_start AND cp.price_reduced = 1 THEN 
			CASE cp.before_plan_id -- use information from the plans table
				WHEN 1 THEN 9.90
				WHEN 2 THEN 19.90
				WHEN 3 THEN 199.0
				ELSE 0
			END
		ELSE 0
	END AS NUMERIC(5,2)) AS amount,
	DENSE_RANK() OVER (PARTITION BY cp.customer_id ORDER BY cp.paymant_date) AS payment_order
FROM customer_payments_CTE cp
INNER JOIN plans p
ON cp.plan_id = p.plan_id
WHERE cp.paymant_date != cp.next_plan_start; -- filter out any duplicate payments from old and new plans
````

![Zrzut ekranu 2024-10-03 142032](https://github.com/user-attachments/assets/b326e985-a16b-4eb0-806e-0e7273004dc2)


***

### Final thoughts

To improve the database, we need to make some changes:

1. In the ```subscriptions``` table, add the ```subscription_id``` column as a primary key.
2. In the ```customer_payments``` table, add the ```subscription_id``` column as a foreign key to link the ```subscriptions``` and ```customer_payments``` tables. Delete the ```plan_id``` and ```plan_name``` columns, as they are duplicates of existing information.


#### New Relationship Diagram

![Zrzut ekranu 2024-10-03 144954](https://github.com/user-attachments/assets/232cb759-b67b-4ed5-8550-a370ea17d130)
