"""Load generated CSV files into PostgreSQL using psycopg's COPY protocol."""
from __future__ import annotations
import argparse
import csv
import os
from pathlib import Path
import psycopg

TABLE_COLUMNS = {
    "users": "user_id, signup_date, city, acquisition_channel",
    "products": "product_id, name, category, price",
    "sessions": "session_id, user_id, device, start_time, discount_offered",
    "events": "event_id, session_id, product_id, event_type, event_time",
    "orders": "order_id, user_id, session_id, purchase_event_id, total_amount, discount, payment_method",
}

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, default=Path("data"))
    parser.add_argument("--dsn", default=os.getenv("DATABASE_URL"), help="PostgreSQL DSN; defaults to DATABASE_URL")
    parser.add_argument("--truncate", action="store_true", help="Clear existing tables before loading")
    args = parser.parse_args()
    if not args.dsn:
        parser.error("Set DATABASE_URL or pass --dsn")
    with psycopg.connect(args.dsn) as conn:
        with conn.cursor() as cur:
            if args.truncate:
                cur.execute("TRUNCATE orders, events, sessions, products, users RESTART IDENTITY CASCADE")
            for table, columns in TABLE_COLUMNS.items():
                path = args.data_dir / f"{table}.csv"
                if not path.exists():
                    raise FileNotFoundError(f"Missing {path}; run generate_data.py first")
                # COPY FROM STDIN streams the file without loading the full CSV into memory.
                with path.open("r", encoding="utf-8", newline="") as source:
                    next(source)  # header
                    with cur.copy(f"COPY {table} ({columns}) FROM STDIN WITH (FORMAT CSV)") as copy:
                        for line in source:
                            copy.write(line)
                print(f"Loaded {table}: {sum(1 for _ in path.open(encoding='utf-8')) - 1:,} rows")

if __name__ == "__main__":
    main()
