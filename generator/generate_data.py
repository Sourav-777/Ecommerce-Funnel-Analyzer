"""Generate a deterministic, relationally coherent e-commerce funnel dataset."""
from __future__ import annotations

import argparse
from pathlib import Path
import numpy as np
import pandas as pd
from faker import Faker

SEED = 42
CATEGORIES = {
    "Apparel": [("Everyday T-shirt", 24.0), ("Relaxed hoodie", 58.0), ("Classic denim", 74.0), ("Running jacket", 96.0)],
    "Home": [("Ceramic mug set", 28.0), ("Cotton throw", 64.0), ("Desk lamp", 82.0), ("Storage basket", 42.0)],
    "Beauty": [("Daily moisturizer", 32.0), ("Vitamin C serum", 48.0), ("Cleanser duo", 36.0), ("Hydration kit", 68.0)],
    "Electronics": [("Wireless earbuds", 89.0), ("Portable speaker", 119.0), ("Charging dock", 54.0), ("Smart desk light", 105.0)],
    "Sports": [("Yoga mat", 46.0), ("Training bottle", 22.0), ("Resistance bands", 30.0), ("Trail backpack", 92.0)],
}
CHANNELS = ["Google", "Instagram", "Email", "Direct"]
DEVICES = ["mobile", "desktop", "tablet"]
PAYMENT_METHODS = ["card", "paypal", "wallet"]


def generate(output: Path, target_events: int, seed: int) -> dict[str, int]:
    if target_events < 1000:
        raise ValueError("target-events must be at least 1000")
    rng = np.random.default_rng(seed)
    fake = Faker()
    Faker.seed(seed)
    output.mkdir(parents=True, exist_ok=True)

    products = []
    for category, items in CATEGORIES.items():
        for name, price in items:
            products.append({"product_id": len(products) + 1, "name": name, "category": category, "price": price})
    products_df = pd.DataFrame(products)

    # Sessions per user is overdispersed, yielding a meaningful returning cohort.
    n_users = max(1000, int(target_events / 4.2))
    user_channels = rng.choice(CHANNELS, n_users, p=[.36, .27, .17, .20])
    user_dates = pd.Timestamp("2025-01-01") + pd.to_timedelta(rng.integers(0, 365, n_users), unit="D")
    users = pd.DataFrame({
        "user_id": np.arange(1, n_users + 1), "signup_date": user_dates.date,
        "city": [fake.city() for _ in range(n_users)], "acquisition_channel": user_channels,
    })
    # Target sessions are scaled so the expected event count is near the requested amount.
    n_sessions = max(1000, int(target_events / 2.4))
    session_users = rng.integers(1, n_users + 1, n_sessions)
    signup_by_user = users.set_index("user_id")["signup_date"]
    session_start = pd.to_datetime(signup_by_user.loc[session_users].to_numpy()) + pd.to_timedelta(
        rng.integers(0, 180 * 24 * 60, n_sessions), unit="m"
    )
    device = rng.choice(DEVICES, n_sessions, p=[.62, .30, .08])
    sessions = pd.DataFrame({"session_id": np.arange(1, n_sessions + 1), "user_id": session_users,
                             "device": device, "start_time": session_start})
    channel_by_user = users.set_index("user_id")["acquisition_channel"]
    # Discount exposure is assigned at session level; it improves stage progression.
    discounted = rng.random(n_sessions) < .31
    sessions["discount_offered"] = discounted
    event_rows, order_rows = [], []
    event_id = order_id = 1
    product_categories = list(CATEGORIES.keys())
    category_weights = np.array([.24, .19, .20, .18, .19])
    product_prices = products_df.set_index("product_id")["price"].to_dict()
    for i, row in sessions.iterrows():
        sid, uid, dev = int(row.session_id), int(row.user_id), row.device
        start = row.start_time
        channel = channel_by_user.loc[uid]
        cat = rng.choice(product_categories, p=category_weights)
        cat_products = products_df.loc[products_df.category == cat, "product_id"].to_numpy()
        pid = int(rng.choice(cat_products))
        # The same session can view multiple products; funnel event rows remain ordered.
        view_count = int(rng.choice([1, 2, 3], p=[.55, .32, .13]))
        offsets = sorted(rng.integers(0, 18, view_count).tolist())
        for off in offsets:
            event_rows.append((event_id, sid, pid, "view", start + pd.Timedelta(minutes=int(off))))
            event_id += 1
        mobile_factor = .76 if dev == "mobile" else (1.10 if dev == "desktop" else .92)
        channel_factor = {"Google": 1.04, "Instagram": .88, "Email": 1.20, "Direct": 1.0}[channel]
        disc_factor = 1.38 if discounted[i] else 1.0
        add_p = np.clip(.34 * mobile_factor * channel_factor * disc_factor, .08, .72)
        if rng.random() >= add_p:
            continue
        t = start + pd.Timedelta(minutes=20)
        event_rows.append((event_id, sid, pid, "add_to_cart", t)); event_id += 1
        checkout_p = np.clip(.62 * mobile_factor * channel_factor * disc_factor, .20, .90)
        if rng.random() >= checkout_p:
            continue
        t += pd.Timedelta(minutes=int(rng.integers(2, 12)))
        event_rows.append((event_id, sid, pid, "begin_checkout", t)); event_id += 1
        # Payment attempt is observable regardless of outcome. Failures may be retried.
        t += pd.Timedelta(minutes=int(rng.integers(1, 6)))
        event_rows.append((event_id, sid, pid, "payment_attempt", t)); event_id += 1
        fail_p = .19 if dev == "mobile" else (.10 if dev == "desktop" else .14)
        failed = rng.random() < fail_p
        if failed and rng.random() < .54:
            t += pd.Timedelta(minutes=int(rng.integers(1, 5)))
            event_rows.append((event_id, sid, pid, "payment_attempt", t)); event_id += 1
            failed = rng.random() < .23
        # Conditional conversion illustrates improved conversion under discount.
        purchase_p = (.57 if not failed else .03) * (1.22 if discounted[i] else 1.0)
        purchase_p *= (1.08 if dev == "desktop" else (.78 if dev == "mobile" else .92))
        if rng.random() < min(purchase_p, .88):
            t += pd.Timedelta(minutes=int(rng.integers(1, 4)))
            event_rows.append((event_id, sid, pid, "purchase", t)); event_id += 1
            event_id_for_purchase = event_id - 1
            discount_rate = float(rng.choice([.05, .10, .15])) if discounted[i] else 0.0
            price = float(product_prices[pid])
            order_rows.append((order_id, uid, sid, event_id_for_purchase, round(price * (1 - discount_rate), 2),
                               round(price * discount_rate, 2), str(rng.choice(PAYMENT_METHODS))))
            order_id += 1

    events = pd.DataFrame(event_rows, columns=["event_id", "session_id", "product_id", "event_type", "event_time"])
    events["event_time"] = pd.to_datetime(events.event_time)
    orders = pd.DataFrame(order_rows, columns=["order_id", "user_id", "session_id", "purchase_event_id", "total_amount", "discount", "payment_method"])
    # Clip by generating only full sessions; disclose achieved count (close to target).
    tables = {"users": users, "products": products_df, "sessions": sessions, "events": events, "orders": orders}
    for name, frame in tables.items():
        frame.to_csv(output / f"{name}.csv", index=False, date_format="%Y-%m-%d %H:%M:%S")
    return {name: len(frame) for name, frame in tables.items()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("data"))
    parser.add_argument("--target-events", type=int, default=300_000)
    parser.add_argument("--seed", type=int, default=SEED)
    args = parser.parse_args()
    counts = generate(args.output, args.target_events, args.seed)
    print("Generated rows:", ", ".join(f"{k}={v:,}" for k, v in counts.items()))
