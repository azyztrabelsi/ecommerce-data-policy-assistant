# KPI dictionary

Data is historical Olist data (not a live store). Amounts are in Brazilian reais.
Dataset period: 4 September 2016 to 17 October 2018 (order purchase dates).

## Global rules
- Valid orders: every status except `canceled` and `unavailable`.
- Customers are counted with `customer_unique_id`, never `customer_id`
  (customer_id is created per order).
- Item price, freight value and payment value are different amounts and are never added together.
- Child tables (items, payments, reviews) are aggregated per order BEFORE joining.
- Review score: average per order first, then average across orders.
- Category: English name, else Portuguese name, else 'unknown' (LEFT JOIN on the translation table).

## KPIs and verified values
| KPI | Definition | Source | Verified value |
|---|---|---|---|
| Total orders | COUNT of rows in orders (all statuses) | orders | 99,441 |
| Valid orders | Orders not canceled or unavailable | orders | 98,207 (99,441 - 625 - 609) |
| Cancellation rate | Canceled orders / all orders | orders | 0.63% |
| Unique customers | COUNT(DISTINCT customer_unique_id) | customers | 96,096 |
| Repeat customers | customer_unique_id with more than 1 order | customers | 2,997 |
| Item sales | SUM(price), excludes freight | order_items | 13,591,643.70 (all statuses) |
| Payment total | SUM(payment_value), all payment types | order_payments | about 16,008,872 (all statuses) |
| Late delivery rate | Delivered orders with delivery date after estimated date / delivered orders that have a delivery date | orders | 8.11% |
| Delivery time | Delivered date minus purchase date, in days, delivered orders only | orders | 12.5 days |
| Avg items per order | Items per valid order that has items | order_items | 1.14 |
| Avg credit card installments | AVG(payment_installments), credit_card | order_payments | 3.51 |
| Seller order volume | COUNT(DISTINCT order_id) per seller, valid orders | order_items | see Q4 |

## Known data quirks
- No orders in November 2016, and only one tiny sale in December 2016. Early months are almost empty.
- About 775 orders have no items, one order has no payment row, and about 770 orders have no review.
- 547 orders have more than one review, and review_id is not unique.
- `payment_type = 'not_defined'` appears for 3 orders with payment value 0. These rows are kept as they are.
- One category is misspelled in the source data (`costruction_tools_tools`) and is kept unchanged.
- Payment total is higher than item sales plus freight because of installment interest and vouchers.
- Geolocation has duplicate rows per zip prefix, so `geolocation_clean` keeps one row per prefix.