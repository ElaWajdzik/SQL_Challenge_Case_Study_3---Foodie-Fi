# <p align="center"> Case Study #3: 🥑 Foodie-Fi
 
## <p align="center"> D. Outside The Box Questions

The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

### 1. How would you calculate the rate of growth for Foodie-Fi?

#### Startegia A - The rate of growth based on number of customers 

In the dataset, the data mostly comes from 2020, which is why the best way to calculate the growth rate is to use monthly periods. This parameters is also useful to monitor over different time periods (e.g. weekly, quarterly, yearly). If we take a longer spread of time, this parameter will better show the long-term trends.
<br><br>
$$
Growth Rate = \frac{Customers\_Current\_month - Customers\_Previous\_month}{Customers\_Previous\_month}  x  100
$$

Based on the calculated data on the number of new customers and new paying customers, aggregated by each month (SQL code below), I have prepared visualizations of the Growth Rate. The growth rate shows significant fluctuations from month to month. Overall, it tends to hover around 0%. If Foodie-Fi wants to grow, they should focus more on outbound campaigns and implement more marketing strategies to build a larger customer base and establish a strong, healthy business.
<br><br>


````sql
WITH all_customers AS (
	SELECT 
		customer_id,
		MIN(start_date) AS start_date
	FROM subscriptions
	GROUP BY customer_id),

new_customers AS (
	SELECT 
		DATETRUNC(month, start_date) AS start_date,
		COUNT(DISTINCT customer_id) AS new_customers
	FROM all_customers
	GROUP BY DATETRUNC(month, start_date)),

all_paying_customers AS (
	SELECT 
		customer_id,
		MIN(start_date) AS start_date
	FROM subscriptions
	WHERE plan_id IN (1,2,3)
	GROUP BY customer_id),

new_paying_customers AS (
	SELECT 
		DATETRUNC(month, start_date) AS start_date,
		COUNT(DISTINCT customer_id) As new_paying_customers
	FROM all_paying_customers
	GROUP BY DATETRUNC(month, start_date))

SELECT 
	nc.start_date AS month_date,
	nc.new_customers,
	pc.new_paying_customers
FROM new_customers nc
LEFT JOIN new_paying_customers pc
ON pc.start_date = nc.start_date;
````

#### Startegia B - The rate of growth based on revenue 
<br><br>
$$
Growth Rate = \frac{Revenue\_Current\_month - Revenue\_Previous\_month}{Revenue\_Previous\_month} x 100
$$
<br><br>
As in **strategi A** I calculated the growth rate is to use monthly periods. Based on the data in the ```customer_payments```  table, I aggregated the revenue by each month (SQL code below). I have prepared visualizations of the Growth Rate. The growth rate shows a significant decline at the end of the year. The revenue grew from the beginning of 2020 but slowed down in the second half of the year. To provide a complete picture, I also added a chart showing the revenue value for each month.

Another approach to measuring growth would be to calculate the rate of growth based on profit, but in this dataset, we don't have data on costs.


````sql
SELECT 
	DATETRUNC(month, payment_date) AS month_date,
	SUM(amount) AS revenue
FROM customer_payments
GROUP BY DATETRUNC(month, payment_date)
ORDER BY DATETRUNC(month, payment_date);
````

***

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

A few key metrics I would recommend Fodie-Fi management to track over time to assess the performance of their overall business are:

* **Number of customers (split by paid and free customers)**: This metric shows whether we are still expanding the market and can retain acquired customers for a longer period of time.

* **Churn rate**: The percentage of customers who stop using the service over time. This metric will indicate if customers are satisfied with Fodie-Fi’s offering.

* **Monthly revenue**: The total amount collected from paid subscriptions.

* **Monthly periodized revenue**: The total amount collected, distributed evenly over the subscription period (e.g., if a customer buys an annual subscription in February, the transaction is divided into twelve equal parts and assigned to each month the subscription is active). This metric helps track consistent revenue growth over time, even when annual plans may introduce seasonal fluctuations.

* **Monthly business costs**: All business-related costs (marketing, employee salaries, website maintenance, etc.). By comparing revenue and costs, we can calculate **net profit**, which is crucial for evaluating the overall health of the business.

* **CAC (Customer Acquisition Cost)**: The total cost of acquiring a new customer, including marketing and sales expenses. It is useful to set a maximum CAC threshold that we aim not to exceed.

* **LTV (Customer Lifetime Value)**: Predicts the net profit a company expects to earn from a customer over the entire duration of their relationship.


***

### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

Every customer starts using Foodie-Fi with a 7-day free trial, after which they can choose a paid subscription (monthly or annual). First, I would analyze **the source of acquisition** for each customer and check if certain sources are better or worse at converting free trial users into paid customers. It would also be helpful to **examine what customers do during the trial period** (e.g., how often they use the platform, what content they watch, etc.) and identify any actions that are common among users who ultimately become paid customers.

Once the key actions correlated with conversion are identified, I would conduct **A/B testing** with new customers. Group A would experience the platform as it is, while Group B would be exposed to changes designed to encourage conversion. For instance, Group B could receive special newsletters showcasing platform features, see tutorials highlighting key functions upon login, or be offered a limited-time discount (e.g., 10% off) on a first subscription.

I would also recommend conducting **satisfaction surveys** for all customers—after the trial, after their first month, and after long-term use. Analyzing the results can reveal strengths and areas for improvement. Additionally, sending **surveys to churned customers** can help identify the main reasons for their departure, though response rates for these surveys are typically low, but even a few responses can provide valuable insights.

Finally, I would **analyze the behavior of long-term customers** compared to those who have churned. For example, customers who are about to churn might stop logging into the platform, which could trigger a reminder email or push notification highlighting a great show or unfinished episodes. This proactive step could re-engage users and reduce future churn.

***

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
***

### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?