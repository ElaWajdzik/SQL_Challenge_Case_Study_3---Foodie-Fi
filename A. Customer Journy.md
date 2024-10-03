# <p align="center"> Case Study #3: 🥑 Foodie-Fi
 
## <p align="center"> A. Customer Journey

Based off the 8 sample customers provided in the sample from the ```subscriptions``` table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!


````sql
-- generate a random list of 8 unique customer IDs.

WITH customers AS (
	SELECT DISTINCT customer_id
	FROM subscriptions)

SELECT 
	TOP 8 * 
FROM customers
ORDER BY NEWID();
````

````sql
-- check how customers changed their plans over time based on popularity

WITH plans_in_time AS (
SELECT 
	customer_id,
	STRING_AGG (plan_id, ',') AS plan_list -- concatenate the information about all plans for each customer in chronological order (by start_date)
FROM subscriptions
GROUP BY customer_id
)

SELECT 
	plan_list,
	COUNT(*) AS customer_number
FROM plans_in_time
GROUP BY plan_list
ORDER BY customer_number DESC;
````

### Sample Data:
![Zrzut ekranu 2024-09-27 234023](https://github.com/user-attachments/assets/fa955da0-fb3a-4fc8-8e93-f4da67096fc7)


### Example of a Customer’s Onboarding Journey:
![Zrzut ekranu 2024-09-27 142815](https://github.com/user-attachments/assets/c9deea62-b548-4cab-8bdf-e0d9e479659e)

### Subscription Rules:
- The trial lasts 7 days.
- After the trial, the customer automatically continue with the Pro Monthly plan.
- If the customer churns, the subscription will end after the current payment period.
- If the customer upgrades from the Basic to the Pro plan, the higher plan begins immediately.
- If the customer downgrades, the plan change will take effect after the current payment period ends.


*** 

### Customer Journeys:

**Customer 12** started their journey with a free trial on 22 Sep 2020. After the trial ended on 29 Sep 2020, they subscribed to the basic monthly planand have remained on this plan since.

<img src="https://github.com/user-attachments/assets/5ee3e17a-ccde-4539-a0d4-048847a773ac"  width="400">

**Custumer 168** started their journey with a free trial on 7 Mar 2020. After the trial ended on 14 Mar 2020, they subscribed to the pro monthly plan, and are still on this plan.

<img src="https://github.com/user-attachments/assets/861f230f-3b1e-4a6f-8baa-4f09524d8f60"  width="400">

**Custumer 354** started their journey with a free trial on 19 Mar 2020. After the trial ended on 26 Mar 2020, they churned and did not subscribe to any plan.

<img src="https://github.com/user-attachments/assets/ecfa42d8-0a0b-43fe-9133-e58e24f801e6" width="400">

**Custumer 432** started their journey with a free trial on 19 Mar 2020. After the trial ended on 26 Mar 2020, they subscribed to the basic monthly plan. On 22 May 2020, they upgraded to the pro annual plan (which started immediately on 22 May).

<img src="https://github.com/user-attachments/assets/f6928b31-2e0a-44f9-8c7a-7bc08c74a4c5" width="400">

**Custumer 470** started their journey with a free trial on 28 Apr 2020. After the trial ended on 5 May 2020, they subscribed to the pro monthly plan. On 8 May 2020, they switched to the pro annual plan.

<img src="https://github.com/user-attachments/assets/a1da93d3-8b97-4b36-8d88-29938fefd5fa" width="400">

**Custumer 901** started their journey with a free trial on 21 Apr 2020. After the trial ended on 28 Apr 2020, they subscribed to the basic monthly plan. On 22 May 2020, they upgraded to the pro monthly plan (which began on the same day).

<img src="https://github.com/user-attachments/assets/1faf81ce-1a35-4937-a8af-d5c4a2fae86d" width="400">

**Custumer 918** started their journey with a free trial on 3 Jun 2020. After the trial ended on 10 Jun 2020, they subscribed to the basic monthly plan. On 1 Sep 2020, they upgraded to the pro monthly plan (which started on 1 Sep). Later, on 1 Dec 2020, they switched to the pro annual plan.

<img src="https://github.com/user-attachments/assets/ed7794c1-1812-4ae0-9025-b243be2a2d91" width="400">

**Custumer 996** started their journey with a free trial on 11 Nov 2020. After the trial ended on 18 Nov 2020, they subscribed to the basic monthly plan. On 7 Dec 2020, they churned, and the plan ended on 17 Dec 2020.

<img src="https://github.com/user-attachments/assets/ce2fc586-62e1-4775-a2ef-b11c6fefa2fe" width="400">
