-- 店铺销量驱动分析
-- 1、店铺销量统计
SELECT DISTINCT type
FROM jd_database_new;

SELECT
    shop_id,
    COUNT(*) AS sales_cnt
FROM jd_database_new
WHERE type = 'Order'
GROUP BY shop_id
ORDER BY sales_cnt DESC;

-- 2. 店铺粉丝数与销量相关性
-- 这里一般按店铺粒度计算相关性：每个店铺一行，包含粉丝数和销量。
WITH shop_sales AS (
    SELECT
        shop_id,
        MAX(fans_number) AS fans_number,
        COUNT(CASE WHEN type = 'Order' THEN 1 END) AS sales_cnt
    FROM jd_database_new
    GROUP BY shop_id
)
SELECT
    (COUNT(*) * SUM(fans_number * sales_cnt) - SUM(fans_number) * SUM(sales_cnt)) /
    SQRT(
        (COUNT(*) * SUM(fans_number * fans_number) - SUM(fans_number) * SUM(fans_number)) *
        (COUNT(*) * SUM(sales_cnt * sales_cnt) - SUM(sales_cnt) * SUM(sales_cnt))
    ) AS fans_sales_corr
FROM shop_sales
WHERE fans_number IS NOT NULL
  AND sales_cnt IS NOT NULL;
  
-- 3. 店铺会员数与销量相关性
WITH shop_sales AS (
    SELECT
        shop_id,
        MAX(vip_number) AS vip_number,
        COUNT(CASE WHEN type = 'Order' THEN 1 END) AS sales_cnt
    FROM jd_database_new
    GROUP BY shop_id
)
SELECT
    (COUNT(*) * SUM(vip_number * sales_cnt) - SUM(vip_number) * SUM(sales_cnt)) /
    SQRT(
        (COUNT(*) * SUM(vip_number * vip_number) - SUM(vip_number) * SUM(vip_number)) *
        (COUNT(*) * SUM(sales_cnt * sales_cnt) - SUM(sales_cnt) * SUM(sales_cnt))
    ) AS vip_sales_corr
FROM shop_sales
WHERE vip_number IS NOT NULL
  AND sales_cnt IS NOT NULL;
  
-- 4. 店铺评分与销量相关性
WITH shop_sales AS (
    SELECT
        shop_id,
        MAX(shop_score) AS shop_score,
        COUNT(CASE WHEN type = 'Order' THEN 1 END) AS sales_cnt
    FROM jd_database_new
    GROUP BY shop_id
)
SELECT
    (COUNT(*) * SUM(shop_score * sales_cnt) - SUM(shop_score) * SUM(sales_cnt)) /
    SQRT(
        (COUNT(*) * SUM(shop_score * shop_score) - SUM(shop_score) * SUM(shop_score)) *
        (COUNT(*) * SUM(sales_cnt * sales_cnt) - SUM(sales_cnt) * SUM(sales_cnt))
    ) AS score_sales_corr
FROM shop_sales
WHERE shop_score IS NOT NULL
  AND sales_cnt IS NOT NULL;

-- 5.根据店铺注册日期划分新老店铺（注册时间在最近3个月内的定义为“新店”，其余为“老店”）
SELECT    
    shop_type, COUNT(DISTINCT shop_id) shop_count, AVG(purchases_cnt) avg_purchases_cnt    
FROM    
    (SELECT    
        shop_id,    
        COUNT(IF(type = 'Order', shop_id, NULL)) purchases_cnt,    
        IF(MIN(shop_register_date) >= DATE_SUB((SELECT MAX(action_date) FROM jd_database_new), INTERVAL 3 MONTH), '新店', '老店') AS shop_type    
    FROM    
        jd_database_new    
    GROUP BY shop_id    
    ) u1    
GROUP BY shop_type;

-- 6.按店铺主营类目统计总销量、平均销量、类目内部的头部店铺销售量占比
SELECT    
    shop_category,    
    SUM(cnt) category_total,    
    ROUND(SUM(cnt) / COUNT(DISTINCT shop_id), 2) avg_purchases,    
    SUM(IF(RK <= 3, cnt, 0)) top3_purchases,    
    CONCAT(ROUND(SUM(IF(RK <= 3, cnt, 0)) / SUM(cnt) * 100, 2), '%') top3_proportion    
FROM    
    (SELECT    
        shop_id, shop_category, COUNT(*) cnt,    
        ROW_NUMBER()OVER(PARTITION BY shop_category ORDER BY COUNT(*) DESC) rk    
    FROM jd_database_new    
    WHERE type = 'Order'    
    GROUP BY shop_id , shop_category    
    ) s1    
GROUP BY shop_category    
ORDER BY SUM(IF(RK <= 3, cnt, 0)) / SUM(cnt) DESC;
