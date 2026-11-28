"""Run every reference query and write the results to docs/reference_results.md."""
import os
import re
from datetime import datetime
from pathlib import Path

import psycopg
from dotenv import load_dotenv

load_dotenv()
SQL_FILE = Path("evaluation/reference_sql_bi.sql")
OUT_FILE = Path("docs/reference_results.md")
MAX_ROWS = 50


def to_table(columns, rows):
    lines = ["| " + " | ".join(columns) + " |",
             "|" + "|".join("---" for _ in columns) + "|"]
    for row in rows[:MAX_ROWS]:
        lines.append("| " + " | ".join(str(v) for v in row) + " |")
    if len(rows) > MAX_ROWS:
        lines.append(f"\n(first {MAX_ROWS} of {len(rows)} rows shown)")
    return "\n".join(lines)


text = SQL_FILE.read_text(encoding="utf-8")
chunks = [c for c in re.split(r"(?m)^-- (?=Q\d+|CHECK)", text) if c.strip()]

out = [
    "# Reference results (verified by running the reference SQL)",
    "",
    f"Generated on {datetime.now():%Y-%m-%d %H:%M} from evaluation/reference_sql_bi.sql "
    "on the local PostgreSQL Olist database. These results are the ground truth "
    "for the Text-to-SQL benchmark.",
    "",
]

with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
    for chunk in chunks:
        title, _, sql = chunk.partition("\n")
        sql = sql.strip()
        print(f"Running: {title}")
        out.append(f"## {title.strip()}")
        out.append("")
        out.append("```sql\n" + sql + "\n```")
        out.append("")
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
                columns = [d.name for d in cur.description]
                out.append(to_table(columns, cur.fetchall()))
        except Exception as e:
            conn.rollback()
            out.append(f"ERROR: {e}")
        out.append("")

OUT_FILE.write_text("\n".join(out), encoding="utf-8")
print(f"\nSaved to {OUT_FILE}")