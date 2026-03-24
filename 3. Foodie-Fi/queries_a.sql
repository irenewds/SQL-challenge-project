USE foodie_fi;

-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
SELECT 
    s.customer_id,
    GROUP_CONCAT(
        CONCAT(p.plan_name, ' (', s.start_date, ')')
        ORDER BY s.start_date
        SEPARATOR ' → '
    ) AS journey
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY s.customer_id
ORDER BY s.customer_id
LIMIT 10;