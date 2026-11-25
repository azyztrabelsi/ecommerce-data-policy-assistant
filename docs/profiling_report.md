# Olist profiling report

## olist_customers_dataset.csv
- Rows: 99,441
- Columns: 5
- Fully duplicated rows: 0
- Single-column key candidates: ['customer_id']

| Column | Type | Null % | Distinct |
|---|---|---|---|
| customer_id | str | 0.00 | 99,441 |
| customer_unique_id | str | 0.00 | 96,096 |
| customer_zip_code_prefix | int64 | 0.00 | 14,994 |
| customer_city | str | 0.00 | 4,119 |
| customer_state | str | 0.00 | 27 |

## olist_geolocation_dataset.csv
- Rows: 1,000,163
- Columns: 5
- Fully duplicated rows: 261,831
- Single-column key candidates: none

| Column | Type | Null % | Distinct |
|---|---|---|---|
| geolocation_zip_code_prefix | int64 | 0.00 | 19,015 |
| geolocation_lat | float64 | 0.00 | 717,372 |
| geolocation_lng | float64 | 0.00 | 717,615 |
| geolocation_city | str | 0.00 | 8,011 |
| geolocation_state | str | 0.00 | 27 |

## olist_order_items_dataset.csv
- Rows: 112,650
- Columns: 7
- Fully duplicated rows: 0
- Single-column key candidates: none

| Column | Type | Null % | Distinct |
|---|---|---|---|
| order_id | str | 0.00 | 98,666 |
| order_item_id | int64 | 0.00 | 21 |
| product_id | str | 0.00 | 32,951 |
| seller_id | str | 0.00 | 3,095 |
| shipping_limit_date | str | 0.00 | 93,318 |
| price | float64 | 0.00 | 5,968 |
| freight_value | float64 | 0.00 | 6,999 |

## olist_order_payments_dataset.csv
- Rows: 103,886
- Columns: 5
- Fully duplicated rows: 0
- Single-column key candidates: none

| Column | Type | Null % | Distinct |
|---|---|---|---|
| order_id | str | 0.00 | 99,440 |
| payment_sequential | int64 | 0.00 | 29 |
| payment_type | str | 0.00 | 5 |
| payment_installments | int64 | 0.00 | 24 |
| payment_value | float64 | 0.00 | 29,077 |

## olist_order_reviews_dataset.csv
- Rows: 99,224
- Columns: 7
- Fully duplicated rows: 0
- Single-column key candidates: none

| Column | Type | Null % | Distinct |
|---|---|---|---|
| review_id | str | 0.00 | 98,410 |
| order_id | str | 0.00 | 98,673 |
| review_score | int64 | 0.00 | 5 |
| review_comment_title | str | 88.34 | 4,527 |
| review_comment_message | str | 58.70 | 36,159 |
| review_creation_date | str | 0.00 | 636 |
| review_answer_timestamp | str | 0.00 | 98,248 |

## olist_orders_dataset.csv
- Rows: 99,441
- Columns: 8
- Fully duplicated rows: 0
- Single-column key candidates: ['order_id', 'customer_id']

| Column | Type | Null % | Distinct |
|---|---|---|---|
| order_id | str | 0.00 | 99,441 |
| customer_id | str | 0.00 | 99,441 |
| order_status | str | 0.00 | 8 |
| order_purchase_timestamp | str | 0.00 | 98,875 |
| order_approved_at | str | 0.16 | 90,733 |
| order_delivered_carrier_date | str | 1.79 | 81,018 |
| order_delivered_customer_date | str | 2.98 | 95,664 |
| order_estimated_delivery_date | str | 0.00 | 459 |

## olist_products_dataset.csv
- Rows: 32,951
- Columns: 9
- Fully duplicated rows: 0
- Single-column key candidates: ['product_id']

| Column | Type | Null % | Distinct |
|---|---|---|---|
| product_id | str | 0.00 | 32,951 |
| product_category_name | str | 1.85 | 73 |
| product_name_lenght | float64 | 1.85 | 66 |
| product_description_lenght | float64 | 1.85 | 2,960 |
| product_photos_qty | float64 | 1.85 | 19 |
| product_weight_g | float64 | 0.01 | 2,204 |
| product_length_cm | float64 | 0.01 | 99 |
| product_height_cm | float64 | 0.01 | 102 |
| product_width_cm | float64 | 0.01 | 95 |

## olist_sellers_dataset.csv
- Rows: 3,095
- Columns: 4
- Fully duplicated rows: 0
- Single-column key candidates: ['seller_id']

| Column | Type | Null % | Distinct |
|---|---|---|---|
| seller_id | str | 0.00 | 3,095 |
| seller_zip_code_prefix | int64 | 0.00 | 2,246 |
| seller_city | str | 0.00 | 611 |
| seller_state | str | 0.00 | 23 |

## product_category_name_translation.csv
- Rows: 71
- Columns: 2
- Fully duplicated rows: 0
- Single-column key candidates: ['product_category_name', 'product_category_name_english']

| Column | Type | Null % | Distinct |
|---|---|---|---|
| product_category_name | str | 0.00 | 71 |
| product_category_name_english | str | 0.00 | 71 |

## Cardinality checks
- orders: order_id unique = True
- orders status counts: {'delivered': 96478, 'shipped': 1107, 'canceled': 625, 'unavailable': 609, 'invoiced': 314, 'processing': 301, 'created': 5, 'approved': 2}
- order_items: (order_id, order_item_id) unique = True
- order_items: orders with more than 1 item = 9,803
- payments: orders with more than 1 payment row = 2,961 (max 29)
- reviews: orders with more than 1 review = 547
- reviews: review_id unique = False
- geolocation: 1,000,163 rows but only 19,015 distinct prefixes