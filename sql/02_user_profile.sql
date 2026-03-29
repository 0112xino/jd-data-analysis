



SELECT
  age_range,
  COUNT(*) AS num,
  CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM jd_database_new) * 100, 3), '%') AS Proportion
FROM jd_database_new
GROUP BY age_range
ORDER BY age_range ASC;

SELECT
  gender,
  COUNT(*) AS num,
  CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM jd_database_new) * 100, 3), '%') AS Proportion
FROM jd_database_new
GROUP BY gender
ORDER BY gender ASC;

SELECT
  customer_level,
  COUNT(*) AS num,
  CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM jd_database_new) * 100, 3), '%') AS Proportion
FROM jd_database_new
GROUP BY customer_level
ORDER BY customer_level ASC;

SELECT
  city_level,
  COUNT(*) AS num,
  CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM jd_database_new) * 100, 3), '%') AS Proportion
FROM jd_database_new
GROUP BY city_level
ORDER BY city_level ASC;

-- 周度用户活跃度统计（PV/UV/人均访问量）
WITH t1 AS (
    SELECT
        action_date,
        FLOOR(DATEDIFF(action_date, '2018-02-01') / 7) AS num,
        COUNT(customer_id) AS pv,
        COUNT(DISTINCT customer_id) AS uv
    FROM jd_database_new
    GROUP BY action_date
),
t2 AS (
    SELECT
        num,
        DATE_ADD('2018-02-01', INTERVAL num * 7 DAY) AS start_date,
        DATE_ADD('2018-02-01', INTERVAL num * 7 + 6 DAY) AS end_date,
        SUM(pv) AS pv,
        SUM(uv) AS uv
    FROM t1
    GROUP BY num
)
SELECT
    CONCAT(start_date, ' 至 ', end_date) AS date,
    pv AS 每周PV,
    uv AS 每周UV,
    ROUND(pv / uv, 2) AS pv_uv
FROM t2
ORDER BY num;

-- 计算用户的平均次日留存率：
SELECT    
    ROUND(SUM(IF(t2.date IS NOT NULL, 1, 0)) / COUNT(t1.date), 4) avg_ret    
FROM    
    (SELECT DISTINCT    
        customer_id, action_date date    
    FROM    
        jd_database_new) t1    
LEFT JOIN    
    (SELECT DISTINCT    
        customer_id, DATE_SUB(action_date, INTERVAL 1 DAY) date    
    FROM    
        jd_database_new) t2    
ON t1.customer_id = t2.customer_id AND t1.date = t2.date    
WHERE t1.date < (SELECT MAX(action_date) FROM jd_database_new);


-- 计算每日新增用户的平均次日留存率：
SELECT    
    ROUND(SUM(IF(t2.date IS NOT NULL, 1, 0)) / COUNT(t1.date), 4) new_avg_ret    
FROM    
    (SELECT    
        customer_id, MIN(action_date) date    
    FROM    
        jd_database_new    
    GROUP BY customer_id) t1    
LEFT JOIN    
    (SELECT DISTINCT    
        customer_id, DATE_SUB(action_date, INTERVAL 1 DAY) date    
    FROM    
        jd_database_new) t2    
ON t1.customer_id = t2.customer_id AND t1.date = t2.date    
WHERE t1.date < (SELECT MAX(action_date) FROM jd_database_new);

