from pathlib import Path
import pandas as pd

RAW = Path("data/raw")
OUT = Path("docs/profiling_report.md")
lines = ["# Olist profiling report", ""]


def log(text=""):
    print(text)
    lines.append(text)


def load(name):
    path = RAW / name
    return pd.read_csv(path) if path.exists() else None


# 1. Profile every CSV
for csv in sorted(RAW.glob("*.csv")):
    df = pd.read_csv(csv)
    keys = [c for c in df.columns if df[c].is_unique and df[c].notna().all()]
    log(f"## {csv.name}")
    log(f"- Rows: {len(df):,}")
    log(f"- Columns: {len(df.columns)}")
    log(f"- Fully duplicated rows: {df.duplicated().sum():,}")
    log(f"- Single-column key candidates: {keys or 'none'}")
    log("")
    log("| Column | Type | Null % | Distinct |")
    log("|---|---|---|---|")
    for c in df.columns:
        log(f"| {c} | {df[c].dtype} | {df[c].isna().mean() * 100:.2f} | {df[c].nunique():,} |")
    log("")

# 2. Cardinality checks that matter for joins
log("## Cardinality checks")
orders = load("olist_orders_dataset.csv")
items = load("olist_order_items_dataset.csv")
pays = load("olist_order_payments_dataset.csv")
revs = load("olist_order_reviews_dataset.csv")
geo = load("olist_geolocation_dataset.csv")

if orders is not None:
    log(f"- orders: order_id unique = {orders['order_id'].is_unique}")
    log(f"- orders status counts: {orders['order_status'].value_counts().to_dict()}")
if items is not None:
    log(f"- order_items: (order_id, order_item_id) unique = "
        f"{not items.duplicated(['order_id', 'order_item_id']).any()}")
    log(f"- order_items: orders with more than 1 item = "
        f"{(items.groupby('order_id').size() > 1).sum():,}")
if pays is not None:
    per_order = pays.groupby("order_id").size()
    log(f"- payments: orders with more than 1 payment row = {(per_order > 1).sum():,} "
        f"(max {per_order.max()})")
if revs is not None:
    log(f"- reviews: orders with more than 1 review = "
        f"{(revs.groupby('order_id').size() > 1).sum():,}")
    log(f"- reviews: review_id unique = {revs['review_id'].is_unique}")
if geo is not None:
    prefix = "geolocation_zip_code_prefix"
    log(f"- geolocation: {len(geo):,} rows but only {geo[prefix].nunique():,} distinct prefixes")

OUT.parent.mkdir(exist_ok=True)
OUT.write_text("\n".join(lines), encoding="utf-8")
print(f"\nReport saved to {OUT}")