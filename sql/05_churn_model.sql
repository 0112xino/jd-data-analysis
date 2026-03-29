-- 构建用户基础特征
CREATE TABLE churn_user_base AS
SELECT DISTINCT
    customer_id,
    age_range,
    gender,
    customer_level,
    city_level,
    DATEDIFF('2018-03-31', customer_register_date) AS register_days
FROM jd_database_new;

-- 构建行为频次特征
CREATE TABLE churn_behavior_feat AS
SELECT
    customer_id,
    COUNT(*) AS action_cnt_60d,
    SUM(CASE WHEN type = 'view' THEN 1 ELSE 0 END) AS view_cnt_60d,
    SUM(CASE WHEN type = 'cart' THEN 1 ELSE 0 END) AS cart_cnt_60d,
    SUM(CASE WHEN type = 'buy' THEN 1 ELSE 0 END) AS buy_cnt_60d,
    SUM(CASE WHEN type = 'follow' THEN 1 ELSE 0 END) AS follow_cnt_60d,
    COUNT(DISTINCT action_date) AS active_days_60d
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 构建最近一次行为距今天数（R值）
CREATE TABLE churn_recency_feat AS
SELECT
    customer_id,
    DATEDIFF('2018-03-31', MAX(action_date)) AS recency_days
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 构建趋势特征
CREATE TABLE churn_trend_feat AS
SELECT
    customer_id,
    SUM(CASE WHEN action_date BETWEEN '2018-03-02' AND '2018-03-31' THEN 1 ELSE 0 END) AS cnt_last_30d,
    SUM(CASE WHEN action_date BETWEEN '2018-02-01' AND '2018-03-01' THEN 1 ELSE 0 END) AS cnt_prev_30d,
    (
        SUM(CASE WHEN action_date BETWEEN '2018-03-02' AND '2018-03-31' THEN 1 ELSE 0 END)
        - SUM(CASE WHEN action_date BETWEEN '2018-02-01' AND '2018-03-01' THEN 1 ELSE 0 END)
    ) * 1.0 /
    (SUM(CASE WHEN action_date BETWEEN '2018-02-01' AND '2018-03-01' THEN 1 ELSE 0 END) + 1) AS behavior_change_rate
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 构建商品偏好特征
CREATE TABLE churn_product_feat AS
SELECT
    customer_id,
    COUNT(DISTINCT product_id) AS product_cnt,
    COUNT(DISTINCT category) AS category_cnt,
    COUNT(DISTINCT brand) AS brand_cnt
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 构建店铺偏好特征
CREATE TABLE churn_shop_feat AS
SELECT
    customer_id,
    COUNT(DISTINCT shop_id) AS shop_cnt,
    AVG(shop_score) AS avg_shop_score,
    AVG(fans_number) AS avg_fans_number,
    AVG(vip_number) AS avg_vip_number
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 构建新品偏好特征
CREATE TABLE churn_new_product_feat AS
SELECT
    customer_id,
    SUM(CASE WHEN product_market_date >= '2017-04-01' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS new_product_ratio
FROM jd_database_new
WHERE action_date BETWEEN '2018-02-01' AND '2018-03-31'
GROUP BY customer_id;

-- 拼接流失预测特征总表
CREATE TABLE churn_feature_table AS
SELECT
    b.customer_id,
    b.age_range,
    b.gender,
    b.customer_level,
    b.city_level,
    b.register_days,

    bf.action_cnt_60d,
    bf.view_cnt_60d,
    bf.cart_cnt_60d,
    bf.buy_cnt_60d,
    bf.follow_cnt_60d,
    bf.active_days_60d,

    rf.recency_days,

    tf.cnt_last_30d,
    tf.cnt_prev_30d,
    tf.behavior_change_rate,

    pf.product_cnt,
    pf.category_cnt,
    pf.brand_cnt,

    sf.shop_cnt,
    sf.avg_shop_score,
    sf.avg_fans_number,
    sf.avg_vip_number,

    npf.new_product_ratio
FROM churn_user_base b
LEFT JOIN churn_behavior_feat bf ON b.customer_id = bf.customer_id
LEFT JOIN churn_recency_feat rf ON b.customer_id = rf.customer_id
LEFT JOIN churn_trend_feat tf ON b.customer_id = tf.customer_id
LEFT JOIN churn_product_feat pf ON b.customer_id = pf.customer_id
LEFT JOIN churn_shop_feat sf ON b.customer_id = sf.customer_id
LEFT JOIN churn_new_product_feat npf ON b.customer_id = npf.customer_id;

-- 构建流失标签  
CREATE TABLE churn_label AS
SELECT
    c.customer_id,
    CASE
        WHEN COUNT(j.customer_id) = 0 THEN 1
        ELSE 0
    END AS label
FROM churn_feature_table c
LEFT JOIN jd_database_new j
    ON c.customer_id = j.customer_id
   AND j.action_date BETWEEN '2018-04-01' AND '2018-04-30'
GROUP BY c.customer_id;

-- 构建最终流失模型数据集
CREATE TABLE churn_model_data AS
SELECT
    f.*,
    l.label
FROM churn_feature_table f
LEFT JOIN churn_label l
    ON f.customer_id = l.customer_id;
    
--  流失用户分层输出   
CREATE TABLE churn_risk_segment AS
SELECT
    customer_id,
    recency_days,
    action_cnt_60d,
    behavior_change_rate,
    label,
    CASE
        WHEN recency_days >= 30 AND action_cnt_60d <= 3 THEN '高风险流失'
        WHEN recency_days BETWEEN 15 AND 29 THEN '中风险流失'
        ELSE '低风险流失'
    END AS churn_level
FROM churn_model_data;


-- 流失用户占比
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS churn_users,
    ROUND(
        SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS churn_rate_percent
FROM churn_model_data;

-- 高 / 中 / 低风险用户占比
SELECT
    churn_level,
    COUNT(*) AS user_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS user_ratio_percent
FROM churn_risk_segment
GROUP BY churn_level
ORDER BY 
    CASE churn_level
        WHEN '高风险流失' THEN 1
        WHEN '中风险流失' THEN 2
        WHEN '低风险流失' THEN 3
        ELSE 4
    END;
    

-- 高风险用户典型特征统计
SELECT
    COUNT(*) AS high_risk_users,

    SUM(CASE WHEN buy_cnt_60d = 0 THEN 1 ELSE 0 END) AS no_buy_users,
    ROUND(SUM(CASE WHEN buy_cnt_60d = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_buy_ratio_percent,

    SUM(CASE WHEN behavior_change_rate < 0 THEN 1 ELSE 0 END) AS behavior_decline_users,
    ROUND(SUM(CASE WHEN behavior_change_rate < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS behavior_decline_ratio_percent,

    SUM(CASE WHEN cart_cnt_60d = 0 THEN 1 ELSE 0 END) AS no_cart_users,
    ROUND(SUM(CASE WHEN cart_cnt_60d = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_cart_ratio_percent
FROM churn_model_data
WHERE customer_id IN (
    SELECT customer_id
    FROM churn_risk_segment
    WHERE churn_level = '高风险流失'
);

-- 流失总体统计表
CREATE TABLE churn_overall_stats AS
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS churn_users,
    ROUND(SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_percent
FROM churn_model_data;

-- 风险分层统计表
CREATE TABLE churn_level_stats AS
SELECT
    churn_level,
    COUNT(*) AS user_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS user_ratio_percent
FROM churn_risk_segment
GROUP BY churn_level;

-- 高风险特征统计表
CREATE TABLE churn_high_risk_profile AS
SELECT
    COUNT(*) AS high_risk_users,
    SUM(CASE WHEN buy_cnt_60d = 0 THEN 1 ELSE 0 END) AS no_buy_users,
    ROUND(SUM(CASE WHEN buy_cnt_60d = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_buy_ratio_percent,

    SUM(CASE WHEN behavior_change_rate < 0 THEN 1 ELSE 0 END) AS behavior_decline_users,
    ROUND(SUM(CASE WHEN behavior_change_rate < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS behavior_decline_ratio_percent,

    SUM(CASE WHEN cart_cnt_60d = 0 THEN 1 ELSE 0 END) AS no_cart_users,
    ROUND(SUM(CASE WHEN cart_cnt_60d = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_cart_ratio_percent
FROM churn_model_data
WHERE customer_id IN (
    SELECT customer_id
    FROM churn_risk_segment
    WHERE churn_level = '高风险流失'
);
