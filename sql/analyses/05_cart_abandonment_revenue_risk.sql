-- Expected cart value is an estimate based on each session's last viewed/carted product price.
WITH carts AS (
 SELECT e.session_id, BOOL_OR(e.event_type='purchase') AS purchased,
        MAX(p.price) FILTER (WHERE e.event_type IN ('view','add_to_cart')) AS indicative_cart_value
 FROM events e JOIN products p USING(product_id)
 WHERE e.event_type IN ('view','add_to_cart','begin_checkout','payment_attempt','purchase')
 GROUP BY e.session_id
 HAVING BOOL_OR(e.event_type='add_to_cart')
)
SELECT COUNT(*) AS cart_sessions,
       COUNT(*) FILTER (WHERE NOT purchased) AS abandoned_carts,
       ROUND(100.0*COUNT(*) FILTER (WHERE NOT purchased)/NULLIF(COUNT(*),0),2) AS cart_abandonment_pct,
       ROUND(SUM(indicative_cart_value) FILTER (WHERE NOT purchased),2) AS gross_revenue_at_risk_estimate
FROM carts;
