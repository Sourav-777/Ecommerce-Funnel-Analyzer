WITH counts AS (
 SELECT COUNT(*) AS sessions,
        COUNT(*) FILTER (WHERE viewed) AS viewed,
        COUNT(*) FILTER (WHERE added_to_cart) AS added_to_cart,
        COUNT(*) FILTER (WHERE began_checkout) AS began_checkout,
        COUNT(*) FILTER (WHERE payment_attempts>0) AS attempted_payment,
        COUNT(*) FILTER (WHERE purchased) AS purchased
 FROM v_session_funnel
), steps AS (
 SELECT * FROM counts
)
SELECT step, sessions_reached,
       ROUND(100.0 * sessions_reached / NULLIF(LAG(sessions_reached) OVER (ORDER BY step_order),0),2) AS pct_of_previous_step,
       ROUND(100.0 * (1 - sessions_reached::numeric / NULLIF(LAG(sessions_reached) OVER (ORDER BY step_order),0)),2) AS dropoff_pct
FROM steps
CROSS JOIN LATERAL (VALUES
 (1,'view'::text,viewed),(2,'add_to_cart',added_to_cart),(3,'begin_checkout',began_checkout),
 (4,'payment_attempt',attempted_payment),(5,'purchase',purchased)
) AS x(step_order,step,sessions_reached)
ORDER BY step_order;
