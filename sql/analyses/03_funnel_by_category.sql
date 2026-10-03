SELECT category, COUNT(DISTINCT session_id) AS sessions_viewed,
       COUNT(DISTINCT session_id) FILTER (WHERE event_type='add_to_cart') AS sessions_carted,
       COUNT(DISTINCT session_id) FILTER (WHERE event_type='begin_checkout') AS sessions_checked_out,
       COUNT(DISTINCT session_id) FILTER (WHERE event_type='purchase') AS sessions_purchased,
       ROUND(100.0*COUNT(DISTINCT session_id) FILTER (WHERE event_type='purchase')/NULLIF(COUNT(DISTINCT session_id),0),2) AS conversion_pct
FROM events e JOIN products p USING(product_id)
GROUP BY category ORDER BY conversion_pct DESC;
