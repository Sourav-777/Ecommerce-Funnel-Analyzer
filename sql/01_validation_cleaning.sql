-- Run after loading. These queries are intentionally read-only and surface quality issues.
-- 1) Duplicate primary/business keys (each result should be empty).
SELECT 'users' AS table_name, user_id::text AS key, COUNT(*) FROM users GROUP BY user_id HAVING COUNT(*) > 1
UNION ALL SELECT 'sessions', session_id::text, COUNT(*) FROM sessions GROUP BY session_id HAVING COUNT(*) > 1
UNION ALL SELECT 'events', event_id::text, COUNT(*) FROM events GROUP BY event_id HAVING COUNT(*) > 1;

-- 2) Broken relationships (FK constraints should already prevent these).
SELECT 'session_without_user' AS issue, COUNT(*) AS rows
FROM sessions s LEFT JOIN users u USING (user_id) WHERE u.user_id IS NULL
UNION ALL
SELECT 'event_without_session_or_product', COUNT(*)
FROM events e LEFT JOIN sessions s USING (session_id) LEFT JOIN products p USING (product_id)
WHERE s.session_id IS NULL OR p.product_id IS NULL
UNION ALL
SELECT 'order_without_matching_purchase_event', COUNT(*)
FROM orders o LEFT JOIN events e ON e.event_id=o.purchase_event_id AND e.event_type='purchase' AND e.session_id=o.session_id
WHERE e.event_id IS NULL;

-- 3) Sequence anomalies: purchase must follow checkout; event times must not precede session start.
WITH per_session AS (
 SELECT s.session_id, s.start_time,
        MIN(e.event_time) FILTER (WHERE event_type='begin_checkout') AS checkout_at,
        MIN(e.event_time) FILTER (WHERE event_type='purchase') AS purchase_at,
        MIN(e.event_time) AS first_event
 FROM sessions s JOIN events e USING (session_id) GROUP BY s.session_id,s.start_time
)
SELECT * FROM per_session
WHERE first_event < start_time OR (purchase_at IS NOT NULL AND (checkout_at IS NULL OR purchase_at < checkout_at));

-- 4) Cleaning view: normalize labels and create a canonical session start date.
CREATE OR REPLACE VIEW v_clean_events AS
SELECT e.event_id, e.session_id, e.product_id,
       LOWER(TRIM(e.event_type)) AS event_type,
       e.event_time,
       e.event_time::date AS event_date
FROM events e
WHERE e.event_type IN ('view','add_to_cart','begin_checkout','payment_attempt','purchase');
