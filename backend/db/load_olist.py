import csv
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ["DATABASE_URL"]
RAW = Path("data/raw")
SQL_FILE = Path(__file__).with_name("schema_core.sql")

# file name -> (staging table, row count seen in the profiling report)
FILES = {
    "olist_customers_dataset.csv": ("customers", 99441),
    "olist_geolocation_dataset.csv": ("geolocation", 1000163),
    "olist_order_items_dataset.csv": ("order_items", 112650),
    "olist_order_payments_dataset.csv": ("order_payments", 103886),
    "olist_order_reviews_dataset.csv": ("order_reviews", 99224),
    "olist_orders_dataset.csv": ("orders", 99441),
    "olist_products_dataset.csv": ("products", 32951),
    "olist_sellers_dataset.csv": ("sellers", 3095),
    "product_category_name_translation.csv": ("category_translation", 71),
}


def load_staging(conn):
    with conn.cursor() as cur:
        cur.execute("DROP SCHEMA IF EXISTS staging CASCADE")
        cur.execute("CREATE SCHEMA staging")
        for filename, (table, expected) in FILES.items():
            path = RAW / filename
            with open(path, encoding="utf-8-sig", newline="") as f:
                header = next(csv.reader(f))
            cols = ", ".join(f'"{c}" text' for c in header)
            cur.execute(f'CREATE TABLE staging."{table}" ({cols})')

            copy_sql = f'COPY staging."{table}" FROM STDIN WITH (FORMAT csv, HEADER true)'
            with open(path, "rb") as f, cur.copy(copy_sql) as copy:
                while chunk := f.read(1024 * 1024):
                    copy.write(chunk)

            cur.execute(f'SELECT count(*) FROM staging."{table}"')
            loaded = cur.fetchone()[0]
            status = "OK" if loaded == expected else f"MISMATCH (expected {expected:,})"
            print(f"staging.{table:<22} {loaded:>10,} rows  {status}")
            if loaded != expected:
                raise SystemExit(f"Row count mismatch for {table}")


def build_core(conn):
    with conn.cursor() as cur:
        cur.execute(SQL_FILE.read_text(encoding="utf-8"))
        print("\nCore tables built:")
        for table in [
            "customers", "geolocation_clean", "orders", "order_items",
            "order_payments", "order_reviews", "products", "sellers",
            "category_translation",
        ]:
            cur.execute(f"SELECT count(*) FROM {table}")
            print(f"  {table:<22} {cur.fetchone()[0]:>10,} rows")


if __name__ == "__main__":
    with psycopg.connect(DATABASE_URL) as conn:
        load_staging(conn)
        build_core(conn)
    print("\nDone.")