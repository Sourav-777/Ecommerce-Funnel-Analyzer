-- Compares conversion against recorded offer exposure for every session.
-- This is a simulated association, not a causal experiment.
SELECT CASE WHEN discount_offered THEN 'discount offered' ELSE 'no discount offered' END AS offer_group,
       COUNT(*) AS sessions,
       COUNT(*) FILTER (WHERE purchased) AS purchases,
       ROUND(100.0*COUNT(*) FILTER (WHERE purchased)/NULLIF(COUNT(*),0),2) AS session_conversion_pct,
       ROUND(AVG(o.total_amount),2) AS avg_net_order_value
FROM v_session_funnel f LEFT JOIN v_session_order o USING(session_id)
GROUP BY offer_group ORDER BY offer_group;
