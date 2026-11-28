# Reference results (verified by running the reference SQL)

Generated on 2026-11-28 11:11 from evaluation/reference_sql_bi.sql on the local PostgreSQL Olist database. These results are the ground truth for the Text-to-SQL benchmark.

## Q0 Dataset period

```sql
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;
```

| first_order | last_order |
|---|---|
| 2016-09-04 21:15:19 | 2018-10-17 17:30:18 |

## Q1 How many orders are recorded?

```sql
SELECT COUNT(*) AS total_orders FROM orders;
```

| total_orders |
|---|
| 99441 |

## Q2 How many orders per status?

```sql
SELECT order_status, COUNT(*) AS orders
FROM orders GROUP BY order_status ORDER BY orders DESC;
```

| order_status | orders |
|---|---|
| delivered | 96478 |
| shipped | 1107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

## Q3 Top 10 product categories by item sales (valid orders)

```sql
SELECT category, ROUND(SUM(price), 2) AS item_sales
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY category ORDER BY item_sales DESC LIMIT 10;
```

| category | item_sales |
|---|---|
| health_beauty | 1255695.13 |
| watches_gifts | 1198185.21 |
| bed_bath_table | 1035964.06 |
| sports_leisure | 979740.92 |
| computers_accessories | 904322.02 |
| furniture_decor | 727465.05 |
| housewares | 626825.80 |
| cool_stuff | 620770.49 |
| auto | 586585.73 |
| garden_tools | 481009.94 |

## Q4 Top 10 sellers by order volume (valid orders)

```sql
SELECT seller_id, COUNT(DISTINCT order_id) AS orders
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY seller_id ORDER BY orders DESC, seller_id LIMIT 10;
```

| seller_id | orders |
|---|---|
| 6560211a19b47992c3666cc44a7e94c0 | 1847 |
| 4a3ca9315b744ce9f8e9374361493884 | 1804 |
| cc419e0650a3c5ba77189a1882b7556a | 1697 |
| 1f50f920176fa81dab994f9023523100 | 1403 |
| da8622b14eb17ae2831f4ac5b9dab84a | 1314 |
| 955fee9216a65b617aa5c0531780ce60 | 1286 |
| 7a67c85e85bb2ce8582c35f2203ad736 | 1159 |
| ea8482cd71df3c1969d7b9473ff13abc | 1145 |
| 4869f7a5dfa277a7dca6462dcf3b52b2 | 1131 |
| 3d871de0142ce09b7081e2b9d1733cb1 | 1076 |

## Q5 Percentage of delivered orders that arrived after the estimated date

```sql
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 2) AS pct_late
FROM v_order_summary
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;
```

| pct_late |
|---|
| 8.11 |

## Q6 Average review score by category (one score per order and category, min 30 orders)

```sql
SELECT category, ROUND(AVG(review_score), 2) AS avg_review_score, COUNT(*) AS orders
FROM (
    SELECT DISTINCT s.order_id, s.category, r.review_score
    FROM v_item_sales s
    JOIN v_order_summary r ON r.order_id = s.order_id
    WHERE r.review_score IS NOT NULL
) x
GROUP BY category HAVING COUNT(*) >= 30
ORDER BY avg_review_score DESC, category LIMIT 10;
```

| category | avg_review_score | orders |
|---|---|---|
| books_general_interest | 4.46 | 508 |
| costruction_tools_tools | 4.43 | 94 |
| books_technical | 4.40 | 257 |
| food_drink | 4.38 | 226 |
| luggage_accessories | 4.33 | 1030 |
| books_imported | 4.32 | 53 |
| small_appliances_home_oven_and_coffee | 4.29 | 75 |
| food | 4.28 | 445 |
| pet_shop | 4.24 | 1701 |
| stationery | 4.24 | 2295 |

## Q7 Monthly item sales (valid orders)

```sql
SELECT purchase_month, ROUND(SUM(price), 2) AS item_sales
FROM v_item_sales
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY purchase_month ORDER BY purchase_month;
```

| purchase_month | item_sales |
|---|---|
| 2016-09 | 207.86 |
| 2016-10 | 44507.30 |
| 2016-12 | 10.90 |
| 2017-01 | 120098.27 |
| 2017-02 | 244959.35 |
| 2017-03 | 368341.32 |
| 2017-04 | 353842.98 |
| 2017-05 | 503159.19 |
| 2017-06 | 429916.61 |
| 2017-07 | 492287.30 |
| 2017-08 | 568245.79 |
| 2017-09 | 621415.91 |
| 2017-10 | 660179.62 |
| 2017-11 | 1003862.14 |
| 2017-12 | 742183.79 |
| 2018-01 | 945456.29 |
| 2018-02 | 837895.43 |
| 2018-03 | 981051.06 |
| 2018-04 | 993592.98 |
| 2018-05 | 992871.75 |
| 2018-06 | 863265.53 |
| 2018-07 | 878044.27 |
| 2018-08 | 848860.10 |
| 2018-09 | 145.00 |

## Q8 Top 5 customer states by number of orders

```sql
SELECT customer_state, COUNT(*) AS orders
FROM v_order_summary GROUP BY customer_state ORDER BY orders DESC LIMIT 5;
```

| customer_state | orders |
|---|---|
| SP | 41746 |
| RJ | 12852 |
| MG | 11635 |
| RS | 5466 |
| PR | 5045 |

## Q9 Orders and payment value by payment type

```sql
SELECT payment_type, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(payment_value), 2) AS payment_total
FROM order_payments GROUP BY payment_type ORDER BY orders DESC;
```

| payment_type | orders | payment_total |
|---|---|---|
| credit_card | 76505 | 12542084.19 |
| boleto | 19784 | 2869361.27 |
| voucher | 3866 | 379436.87 |
| debit_card | 1528 | 217989.79 |
| not_defined | 3 | 0.00 |

## Q10 Average delivery time in days (delivered orders)

```sql
SELECT ROUND(AVG(delivery_days), 1) AS avg_delivery_days
FROM v_order_summary
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;
```

| avg_delivery_days |
|---|
| 12.5 |

## Q11 How many unique customers?

```sql
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers FROM customers;
```

| unique_customers |
|---|
| 96096 |

## Q12 How many customers ordered more than once?

```sql
SELECT COUNT(*) AS repeat_customers
FROM (SELECT customer_unique_id FROM customers
      GROUP BY customer_unique_id HAVING COUNT(*) > 1) x;
```

| repeat_customers |
|---|
| 2997 |

## Q13 Percentage of orders that were canceled

```sql
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'canceled') / COUNT(*), 2) AS pct_canceled
FROM orders;
```

| pct_canceled |
|---|
| 0.63 |

## Q14 Average number of installments for credit card payments

```sql
SELECT ROUND(AVG(payment_installments), 2) AS avg_installments
FROM order_payments WHERE payment_type = 'credit_card';
```

| avg_installments |
|---|
| 3.51 |

## Q15 Average number of items per valid order that has items

```sql
SELECT ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM v_order_summary
WHERE order_status NOT IN ('canceled', 'unavailable') AND item_count IS NOT NULL;
```

| avg_items_per_order |
|---|
| 1.14 |

## CHECK 1 The view must not inflate item totals (both numbers must be equal)

```sql
SELECT (SELECT SUM(items_total) FROM v_order_summary) AS from_view,
       (SELECT SUM(price) FROM order_items)           AS from_table;
```

| from_view | from_table |
|---|---|
| 13591643.70 | 13591643.70 |

## CHECK 2 One row per order in the summary view (both numbers must be equal)

```sql
SELECT (SELECT COUNT(*) FROM v_order_summary) AS view_rows,
       (SELECT COUNT(*) FROM orders)          AS order_rows;
```

| view_rows | order_rows |
|---|---|
| 99441 | 99441 |
