WITH attempts AS (
 SELECT session_id, COUNT(*) AS attempts,
        BOOL_OR(event_type='purchase') AS purchased
 FROM events WHERE event_type IN ('payment_attempt','purchase') GROUP BY session_id
)
SELECT CASE WHEN attempts>1 THEN 'multiple attempts' ELSE 'single attempt' END AS attempt_group,
       COUNT(*) AS checkout_sessions,
       COUNT(*) FILTER (WHERE purchased) AS purchases,
       ROUND(100.0*COUNT(*) FILTER (WHERE purchased)/NULLIF(COUNT(*),0),2) AS recovery_conversion_pct
FROM attempts GROUP BY attempt_group;
