-- Run with psql against the database selected in .env / your connection.
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT PRIMARY KEY,
    signup_date DATE NOT NULL,
    city TEXT NOT NULL,
    acquisition_channel TEXT NOT NULL CHECK (acquisition_channel IN ('Google','Instagram','Email','Direct'))
);
CREATE TABLE IF NOT EXISTS products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price > 0)
);
CREATE TABLE IF NOT EXISTS sessions (
    session_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    device TEXT NOT NULL CHECK (device IN ('mobile','desktop','tablet')),
    discount_offered BOOLEAN NOT NULL DEFAULT FALSE,
    start_time TIMESTAMP NOT NULL
);
CREATE TABLE IF NOT EXISTS events (
    event_id BIGINT PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES sessions(session_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    event_type TEXT NOT NULL CHECK (event_type IN ('view','add_to_cart','begin_checkout','payment_attempt','purchase')),
    event_time TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start ON sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_events_session_type ON events(session_id, event_type);
CREATE INDEX IF NOT EXISTS idx_events_time ON events(event_time);
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    session_id BIGINT NOT NULL REFERENCES sessions(session_id),
    purchase_event_id BIGINT NOT NULL UNIQUE REFERENCES events(event_id),
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    discount NUMERIC(10,2) NOT NULL CHECK (discount >= 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('card','paypal','wallet'))
);

-- Reset in dependency order before reloading generated data.
-- TRUNCATE orders, events, sessions, products, users RESTART IDENTITY CASCADE;
