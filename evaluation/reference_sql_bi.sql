-- Q0 Dataset period
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- Q1 How many orders are recorded?
SELECT COUNT(*) AS total_orders FROM orders;

-- Q2 How many orders per status?
SELECT order_status, COUNT(*) AS orders
FROM orders GROUP BY order_status ORDER BY orders DESC;

-- Q3 Top 10 product categories by item sales (valid orders)
SELECT category, ROUND(SUM(price), 2) AS item_sales
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY category ORDER BY item_sales DESC LIMIT 10;

-- Q4 Top 10 sellers by order volume (valid orders)
SELECT seller_id, COUNT(DISTINCT order_id) AS orders
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY seller_id ORDER BY orders DESC, seller_id LIMIT 10;

-- Q5 Percentage of delivered orders that arrived after the estimated date
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2) AS pct_late
FROM v_order_summary
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;

-- Q6 Average review score by category (one score per order and category, min 30 orders)
SELECT category, ROUND(AVG(review_score), 2) AS avg_review_score, COUNT(*) AS orders
FROM (
    SELECT DISTINCT s.order_id, s.category, r.review_score
    FROM v_item_sales s
    JOIN v_order_summary r ON r.order_id = s.order_id
    WHERE r.review_score IS NOT NULL
) x
GROUP BY category HAVING COUNT(*) >= 30
ORDER BY avg_review_score DESC, category LIMIT 10;

-- Q7 Monthly item sales (valid orders)
SELECT purchase_month, ROUND(SUM(price), 2) AS item_sales
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY purchase_month ORDER BY purchase_month;

-- Q8 Top 5 customer states by number of orders
SELECT customer_state, COUNT(*) AS orders
FROM v_order_summary GROUP BY customer_state ORDER BY orders DESC LIMIT 5;

-- Q9 Orders and payment value by payment type
SELECT payment_type, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(payment_value), 2) AS payment_total
FROM order_payments GROUP BY payment_type ORDER BY orders DESC;

-- Q10 Average delivery time in days (delivered orders)
SELECT ROUND(AVG(delivery_days), 1) AS avg_delivery_days
FROM v_order_summary
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;

-- Q11 How many unique customers?
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers FROM customers;

-- Q12 How many customers ordered more than once?
SELECT COUNT(*) AS repeat_customers
FROM (SELECT customer_unique_id FROM customers
      GROUP BY customer_unique_id HAVING COUNT(*) > 1) x;

-- Q13 Percentage of orders that were canceled
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'canceled') / COUNT(*), 2) AS pct_canceled
FROM orders;

-- Q14 Average number of installments for credit card payments
SELECT ROUND(AVG(payment_installments), 2) AS avg_installments
FROM order_payments WHERE payment_type = 'credit_card';

-- Q15 Average number of items per valid order that has items
SELECT ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM v_order_summary
WHERE order_status NOT IN ('canceled', 'unavailable') AND item_count IS NOT NULL;

-- CHECK 1 The view must not inflate item totals (both numbers must be equal)
SELECT (SELECT SUM(items_total) FROM v_order_summary) AS from_view,
       (SELECT SUM(price) FROM order_items)           AS from_table;

-- CHECK 2 One row per order in the summary view (both numbers must be equal)
SELECT (SELECT COUNT(*) FROM v_order_summary) AS view_rows,
       (SELECT COUNT(*) FROM orders)          AS order_rows;