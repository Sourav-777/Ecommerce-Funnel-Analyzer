-- Common session-level model. A session reaches a step if it contains that event.
CREATE OR REPLACE VIEW v_session_funnel AS
SELECT s.session_id, s.user_id, s.device, u.acquisition_channel,
       s.start_time::date AS session_date,
       (s.start_time::date > MIN(s.start_time::date) OVER (PARTITION BY s.user_id)) AS is_returning,
       s.discount_offered,
       BOOL_OR(e.event_type='view') AS viewed,
       BOOL_OR(e.event_type='add_to_cart') AS added_to_cart,
       BOOL_OR(e.event_type='begin_checkout') AS began_checkout,
       COUNT(*) FILTER (WHERE e.event_type='payment_attempt') AS payment_attempts,
       BOOL_OR(e.event_type='purchase') AS purchased
FROM sessions s JOIN users u USING(user_id)
LEFT JOIN events e USING(session_id)
GROUP BY s.session_id,s.user_id,s.device,u.acquisition_channel,s.start_time,u.signup_date;

CREATE OR REPLACE VIEW v_session_product AS
SELECT DISTINCT s.session_id, s.user_id, s.device, u.acquisition_channel,
       (s.start_time::date > MIN(s.start_time::date) OVER (PARTITION BY s.user_id)) AS is_returning,
       p.product_id,p.category,p.name
FROM sessions s JOIN users u USING(user_id)
JOIN events e USING(session_id) JOIN products p USING(product_id);

CREATE OR REPLACE VIEW v_session_order AS
SELECT s.session_id, s.user_id, s.device, u.acquisition_channel,
       (s.start_time::date > MIN(s.start_time::date) OVER (PARTITION BY s.user_id)) AS is_returning,
       o.total_amount, o.discount, o.payment_method
FROM orders o
JOIN sessions s ON s.session_id = o.session_id
JOIN users u ON u.user_id = s.user_id;
