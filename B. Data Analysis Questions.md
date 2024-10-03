# <p align="center"> Case Study #3: 🥑 Foodie-Fi
 
## <p align="center"> B. Data Analysis Questions


### 1. How many customers has Foodie-Fi ever had?

````sql
SELECT COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions;
````

#### Result:
| number_of_customers |
| ------------------- |
| 1000                |

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

````sql
SELECT 
	DATETRUNC(month, start_date) AS start_of_month, -- truncated to the start tof the month
	COUNT(*) AS number_of_customers
FROM subscriptions
WHERE plan_id = 0 -- select only records related to the trial plan
GROUP BY DATETRUNC(month, start_date)
ORDER BY start_of_month; -- use the alias for the column: DATETRUNC(month, start_date)
````

#### Result:
![Zrzut ekranu 2024-10-02 120444](https://github.com/user-attachments/assets/4fab25c9-a06a-483d-bfe7-5b1fd53460a9)

![Zrzut ekranu 2024-10-02 121235](https://github.com/user-attachments/assets/b63cf1df-926d-4d9c-8823-20a29877a547)


The average number of new customers per month is around 80. The number of new customers starting a trial plan is consistent each month. The largest difference between two months was 26 (with 94 in March and 68 in February), but for the rest of the months, the numbers were quite similar, ranging between 75 and 89.


### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

````sql
SELECT 
	YEAR(s.start_date) AS start_year,
	p.plan_name,
	COUNT(*) AS number_of_plans
FROM subscriptions s
INNER JOIN plans p
ON p.plan_id = s.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY YEAR(s.start_date), p.plan_name;
````

#### Result:

![Zrzut ekranu 2024-10-02 122458](https://github.com/user-attachments/assets/a1fe31e5-4d6d-4ed4-a27a-62af1a7c87b6)

No one started a trial after 2020, which could mean that the plan no longer exists or that the product has stopped attracting new customers. One out of three subscriptions after 2020 was churned, which may indicate that the product is no longer attractive to customers.

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

````sql
DECLARE @n_customer_churn INT; --declare the local variable 
DECLARE @n_customer INT;

SET @n_customer_churn = 
(SELECT
	COUNT(*)
FROM subscriptions
WHERE plan_id = 4);

SET @n_customer =
(SELECT COUNT(DISTINCT customer_id)
FROM subscriptions);

-- print the results
PRINT 'Number of customers who churned: ' + CAST(@n_customer_churn AS VARCHAR);
PRINT 'Percentage of customers who have churned: ' + CAST(CAST(@n_customer_churn * 100.0 / @n_customer AS NUMERIC (4,1)) AS VARCHAR) +'%';
````

#### Steps:
- Declared two integer local variables. The total number of customers is stored in ```@n_customers``` and the number of churned customers is stored in ```@n_customers_churn```.
- Set the values for ```@n_customers``` and ```@n_customers_churn``` based on the data from the ```subscriptions``` table.
- Printed the value of  ```@n_customers_churn``` and calculated the percentage of all customers. The result includes text explaining the number, which is why I changed the data type of results to ```VARCHAR```. 

#### Result:

![Zrzut ekranu 2024-10-02 134851](https://github.com/user-attachments/assets/947a4c83-ab78-4d27-a0b7-9b8db8a1df88)


Almost one in every three customers has churned (30.7%). It would be beneficial to monitor this value over time to determine if this is a baseline churn rate for this business or if it may indicate potential issues.

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

````sql
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
````

#### Result:
![Zrzut ekranu 2024-10-02 154513](https://github.com/user-attachments/assets/d062d5a9-8523-4725-b893-02b9cd90ced5)


9% of all customers churned immediately after the trial. It would be beneficial to monitor this value over time.

### 6. What is the number and percentage of customer plans after their initial free trial?

````sql
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
````

#### Results:
![Zrzut ekranu 2024-10-02 154612](https://github.com/user-attachments/assets/0a3ae517-a92e-4af5-8825-7a4608a444fe)


The largest fraction (87%) of customers decided to purchase monthly subscriptions after the trial, with 55% opting for the Basic Monthly plan and 32% for the Pro Monthly plan.

### 7. What is the customer count and percentage breakdown of all plan_name values at 2020-12-31?

````sql
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
````

#### Result:
![Zrzut ekranu 2024-10-02 154655](https://github.com/user-attachments/assets/7d98df55-e462-4f59-b75e-c4589d79b614)


By the end of 2020, 55% of customers were on a monthly plan, and 19.5% were on an annual plan. This means that three out of four of the total customers had a paid subscription.

### 8. How many customers have upgraded to an annual plan in 2020?

````sql
SELECT 
	COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions
WHERE YEAR(start_date) < 2021
AND plan_id = 3;
````

#### Result:

| number_of_customers |
| ------------------- |
| 195                 |


### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

````sql
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
````

#### Steps:
- Created a temporaty table (CTE) ```customers_with_annual_plan```, which includes the start date of the annual plan for each customer on that plan.
- Created a temporaty table (CTE) ```customers_start_date```, which includes the start date of the trial for each customer.
- Joined the temporary table ```customers_with_annual_plan``` and ```customers_start_date``` using a ```LEFT JOIN ``` clause because I need information only for customers who upgraded to the annual plan.
- Calculate the difference in days between the start of the trial and the start of the annual plan using ```DATEDIFF(day, start_trial, start_annual_plan)``` and applied the ```AVG()``` function on the results.


#### Result:
| avg_days_to_annual_plan |
| ----------------------- |
| 104                     |

On average, customers need three months to upgrade to the annual plan (exactly 104 days). However, it is important to note that the average is not always the best statistic. Question 10 will provide more insight into customer behavior.

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc).

````sql
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
````

#### Steps:
- As in Question 9, I created a temporary table (CTE) ```customers_with_annual_plan``` and ```customers_start_date```.
- Created a temporary table ```customer_with_split_groups``` based on the data about customers who upgraded to the annual plan. The table includes the following information about each customer:
	- ```days_to_annual_plan``` - number of days needed to upgrade, 
	- ```grup_id``` - whole number representing the divided number of days needed to upgrade by 30
- Grouped the data from ```customer_with_split_groups``` by ```group_id``` and base on ```group_id``` added a name for each grupe.

````sql
-- group_name_days

CONCAT(
	CASE group_id 
		WHEN 0 THEN 0
		ELSE (group_id  * 30) +1
	END,
	' - ', 
	(group_id +1) * 30)
````

#### Result:
![Zrzut ekranu 2024-10-02 154736](https://github.com/user-attachments/assets/fdfc0be5-f5b0-4b5e-90ae-0230e0f8f5e8)


Most of the customers (95%) who upgraded to the annual plan did so within 210 days (7 months) of starting the trial. One in five customers with an annual plan upgraded in the first 30 days.

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
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
```

#### Result:
None of the clients of Foodie-Fi downgraded from a Pro Monthly to a Basic Monthly plan in 2020.

