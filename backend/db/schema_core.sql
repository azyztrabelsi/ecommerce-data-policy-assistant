-- Core typed tables, indexes and BI views, built from the staging schema.
-- Re-runnable: drops and rebuilds everything.

DROP VIEW IF EXISTS v_seller_performance, v_item_sales, v_order_summary;
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
    products, sellers, customers, category_translation, geolocation_clean CASCADE;

-- ---------- Core tables ----------
CREATE TABLE customers (
    customer_id               text PRIMARY KEY,   -- one per ORDER, not per person
    customer_unique_id        text NOT NULL,      -- the real customer
    customer_zip_code_prefix  integer,
    customer_city             text,
    customer_state            text
);
INSERT INTO customers
SELECT customer_id, customer_unique_id, customer_zip_code_prefix::integer,
       customer_city, customer_state
FROM staging.customers;

CREATE TABLE sellers (
    seller_id               text PRIMARY KEY,
    seller_zip_code_prefix  integer,
    seller_city             text,
    seller_state            text
);
INSERT INTO sellers
SELECT seller_id, seller_zip_code_prefix::integer, seller_city, seller_state
FROM staging.sellers;

CREATE TABLE category_translation (
    product_category_name          text PRIMARY KEY,
    product_category_name_english  text NOT NULL
);
INSERT INTO category_translation
SELECT product_category_name, product_category_name_english
FROM staging.category_translation;

-- Column names product_name_lenght / product_description_lenght keep the
-- original misspelling from the Olist files.
CREATE TABLE products (
    product_id                   text PRIMARY KEY,
    product_category_name        text,
    product_name_lenght          integer,
    product_description_lenght   integer,
    product_photos_qty           integer,
    product_weight_g             numeric,
    product_length_cm            numeric,
    product_height_cm            numeric,
    product_width_cm             numeric
);
INSERT INTO products
SELECT product_id,
       NULLIF(product_category_name, ''),
       NULLIF(product_name_lenght, '')::numeric::integer,
       NULLIF(product_description_lenght, '')::numeric::integer,
       NULLIF(product_photos_qty, '')::numeric::integer,
       NULLIF(product_weight_g, '')::numeric,
       NULLIF(product_length_cm, '')::numeric,
       NULLIF(product_height_cm, '')::numeric,
       NULLIF(product_width_cm, '')::numeric
FROM staging.products;

CREATE TABLE orders (
    order_id                       text PRIMARY KEY,
    customer_id                    text NOT NULL REFERENCES customers(customer_id),
    order_status                   text NOT NULL,
    order_purchase_timestamp       timestamp,
    order_approved_at              timestamp,
    order_delivered_carrier_date   timestamp,
    order_delivered_customer_date  timestamp,
    order_estimated_delivery_date  timestamp
);
INSERT INTO orders
SELECT order_id, customer_id, order_status,
       NULLIF(order_purchase_timestamp, '')::timestamp,
       NULLIF(order_approved_at, '')::timestamp,
       NULLIF(order_delivered_carrier_date, '')::timestamp,
       NULLIF(order_delivered_customer_date, '')::timestamp,
       NULLIF(order_estimated_delivery_date, '')::timestamp
FROM staging.orders;

CREATE TABLE order_items (
    order_id             text    NOT NULL REFERENCES orders(order_id),
    order_item_id        integer NOT NULL,
    product_id           text    NOT NULL REFERENCES products(product_id),
    seller_id            text    NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date  timestamp,
    price                numeric(10,2) NOT NULL,
    freight_value        numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);
INSERT INTO order_items
SELECT order_id, order_item_id::integer, product_id, seller_id,
       NULLIF(shipping_limit_date, '')::timestamp,
       price::numeric, freight_value::numeric
FROM staging.order_items;

CREATE TABLE order_payments (
    order_id              text    NOT NULL REFERENCES orders(order_id),
    payment_sequential    integer NOT NULL,
    payment_type          text    NOT NULL,
    payment_installments  integer,
    payment_value         numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);
INSERT INTO order_payments
SELECT order_id, payment_sequential::integer, payment_type,
       payment_installments::integer, payment_value::numeric
FROM staging.order_payments;

-- review_id is NOT unique in the source data, so we add a surrogate key.
CREATE TABLE order_reviews (
    review_row_id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id                text,
    order_id                 text NOT NULL REFERENCES orders(order_id),
    review_score             smallint CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title     text,
    review_comment_message   text,
    review_creation_date     timestamp,
    review_answer_timestamp  timestamp
);
INSERT INTO order_reviews
    (review_id, order_id, review_score, review_comment_title,
     review_comment_message, review_creation_date, review_answer_timestamp)
SELECT review_id, order_id, review_score::smallint,
       NULLIF(review_comment_title, ''), NULLIF(review_comment_message, ''),
       NULLIF(review_creation_date, '')::timestamp,
       NULLIF(review_answer_timestamp, '')::timestamp
FROM staging.order_reviews;

-- One row per zip prefix: average coordinates, most common city/state.
CREATE TABLE geolocation_clean AS
SELECT geolocation_zip_code_prefix::integer              AS zip_code_prefix,
       AVG(geolocation_lat::double precision)            AS lat,
       AVG(geolocation_lng::double precision)            AS lng,
       mode() WITHIN GROUP (ORDER BY geolocation_city)   AS city,
       mode() WITHIN GROUP (ORDER BY geolocation_state)  AS state,
       COUNT(*)                                          AS source_rows
FROM staging.geolocation
GROUP BY 1;
ALTER TABLE geolocation_clean ADD PRIMARY KEY (zip_code_prefix);

-- ---------- Indexes ----------
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_status     ON orders(order_status);
CREATE INDEX idx_orders_purchase   ON orders(order_purchase_timestamp);
CREATE INDEX idx_items_product     ON order_items(product_id);
CREATE INDEX idx_items_seller      ON order_items(seller_id);
CREATE INDEX idx_reviews_order     ON order_reviews(order_id);
CREATE INDEX idx_products_category ON products(product_category_name);
CREATE INDEX idx_customers_unique  ON customers(customer_unique_id);

-- ---------- BI views (each child table is aggregated BEFORE joining) ----------
-- Grain: one row per order.
CREATE VIEW v_order_summary AS
SELECT o.order_id,
       c.customer_unique_id,
       c.customer_state,
       o.order_status,
       o.order_purchase_timestamp,
       o.order_delivered_customer_date,
       o.order_estimated_delivery_date,
       (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date) AS delivery_days,
       CASE WHEN o.order_delivered_customer_date IS NULL THEN NULL
            ELSE o.order_delivered_customer_date > o.order_estimated_delivery_date
       END AS is_late,
       i.item_count,
       i.items_total,
       i.freight_total,
       p.payment_total,
       r.review_score
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN (SELECT order_id, COUNT(*) AS item_count,
                  SUM(price) AS items_total, SUM(freight_value) AS freight_total
           FROM order_items GROUP BY order_id) i ON i.order_id = o.order_id
LEFT JOIN (SELECT order_id, SUM(payment_value) AS payment_total
           FROM order_payments GROUP BY order_id) p ON p.order_id = o.order_id
LEFT JOIN (SELECT order_id, ROUND(AVG(review_score), 2) AS review_score
           FROM order_reviews GROUP BY order_id) r ON r.order_id = o.order_id;

-- Grain: one row per order item.
CREATE VIEW v_item_sales AS
SELECT oi.order_id,
       oi.order_item_id,
       oi.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       oi.seller_id,
       s.seller_state,
       oi.price,
       oi.freight_value,
       o.order_status,
       o.order_purchase_timestamp,
       to_char(o.order_purchase_timestamp, 'YYYY-MM') AS purchase_month
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN sellers s  ON s.seller_id = oi.seller_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;

-- Grain: one row per seller.
CREATE VIEW v_seller_performance AS
SELECT oi.seller_id,
       s.seller_state,
       COUNT(DISTINCT oi.order_id) AS order_count,
       COUNT(*)                    AS items_sold,
       SUM(oi.price)               AS items_revenue,
       SUM(oi.freight_value)       AS freight_total
FROM order_items oi
JOIN sellers s ON s.seller_id = oi.seller_id
GROUP BY oi.seller_id, s.seller_state;

ANALYZE;