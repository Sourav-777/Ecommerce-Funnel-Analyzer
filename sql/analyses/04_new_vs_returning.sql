SELECT CASE WHEN f.is_returning THEN 'returning' ELSE 'new' END AS customer_type,
       COUNT(*) AS sessions,
       COUNT(*) FILTER (WHERE f.purchased) AS purchases,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.purchased) / NULLIF(COUNT(*), 0), 2) AS conversion_pct,
       ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM v_session_funnel f
LEFT JOIN v_session_order o USING (session_id)
GROUP BY customer_type
ORDER BY customer_type;