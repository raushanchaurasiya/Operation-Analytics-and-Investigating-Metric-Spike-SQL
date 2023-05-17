create database microsoft;

use microsoft;

select * from job_data;

/*
Calculate the number of jobs reviewed per hour per day for November 2020?
*/

select count(distinct job_id)/(30*24) as jobrev_prhr_prday 
from job_data where ds like '2020-11%';

/*
Throughput: It is the no. of events happening per second.
Your task: Let’s say the above metric is called throughput. 
Calculate 7 day rolling average of throughput? For throughput, do you prefer daily metric or 7-day rolling and why?
*/
DROP TABLE IF EXISTS JOBS_REVIEWED;
CREATE TEMPORARY TABLE JOBS_REVIEWED
(
SELECT ds,count(distinct job_id) as jobs_reviewed,CAST(COUNT(DISTINCT JOB_ID)/86400 AS DECIMAL(10,10)) AS THROUGHPUT 
	from job_data
    group by ds
    order by ds 
);
SELECT ds,jobs_reviewed,throughput
,avg(throughput) OVER(ORDER BY DS ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS throughput_7day
FROM JOBS_REVIEWED
;


/*
Percentage share of each language: Share of each language for different contents.
Your task: Calculate the percentage share of each language in the last 30 days?
*/
SELECT job_id,language,count(language) AS LANG_COUNT,
ROUND((COUNT(LANGUAGE)/6),2)*100 AS PERCENTAGE
from job_data
group by job_id,language
;

/*
Duplicate rows: Rows that have the same value present in them.
Your task: Let’s say you see some duplicate rows in the data. How will you display duplicates from the table?
*/

SELECT ds,a.job_id,language
FROM job_data
INNER JOIN 
(SELECT job_id,count(job_id) as dup_id
FROM job_data
GROUP BY job_id
HAVING dup_id>1
) a 
ON a.job_id=job_data.job_id
;




-- CASE STUDY -2 


select * from users;
select * from events;
select * from email_events;


/*
User Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service.
Your task: Calculate the weekly user engagement?
*/

SELECT WEEK(str_to_date(occured_at,'%Y-%m-%d')) as weekNumber,
		count(user_id) as UserCount
        from events
        group by weekNumber;
        
/*
User Growth: Amount of users growing over time for a product.
Your task: Calculate the user growth for product?
*/

SELECT WEEK(STR_TO_DATE(created_at,'%Y-%m-%d')) AS week_num,
COUNT(user_id) NoOfUsers,
COUNT(USER_ID) - LAG(COUNT(user_id),1) OVER(ORDER BY WEEK(STR_TO_DATE(created_at,'%Y-%m-%d')))  AS user_growth
FROM users
GROUP BY week_num
order by week_num;

/*
Weekly Retention: Users getting retained weekly after signing-up for a product.
Your task: Calculate the weekly retention of users-sign up cohort?
*/

SELECT
COUNT(user_id),
SUM(CASE
WHEN retention_week = 1 THEN 1
ELSE 0
END) AS week_1
FROM
(SELECT
a.user_id,
a.signup_week,
b.engagement_week,
b.engagement_week - a.signup_week AS retention_week
FROM
((SELECT DISTINCT
user_id, EXTRACT(WEEK FROM occured_at) AS signup_week
FROM
events
WHERE
event_type = 'signup_flow'
AND event_name = 'complete_signup'
AND EXTRACT(WEEK FROM occured_at) = 18) a
LEFT JOIN (SELECT DISTINCT
user_id, EXTRACT(WEEK FROM occured_at) AS engagement_week
FROM
events

WHERE
event_type = 'engagement') b ON a.user_id = b.user_id)
ORDER BY a.user_id) a;


/*
Weekly Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service weekly.
Your task: Calculate the weekly engagement per device?
*/

SELECT 
    device,
    WEEK(STR_TO_DATE(occured_at, '%Y-%m-%d')) AS week_num,
    COUNT(user_id) AS total_users
FROM
    events
WHERE
    event_type = 'engagement'
GROUP BY device , week_num
ORDER BY week_num DESC;

/*
Email Engagement: Users engaging with the email service.
Your task: Calculate the email engagement metrics?
*/

SELECT
100.0 * SUM(CASE
WHEN email_cat = 'email_open' THEN 1

ELSE 0
END) / SUM(CASE
WHEN email_cat = 'email_sent' THEN 1
ELSE 0
END) AS email_open_rate,
100.0 * SUM(CASE
WHEN email_cat = 'email_clicked' THEN 1
ELSE 0
END) / SUM(CASE
WHEN email_cat = 'email_sent' THEN 1
ELSE 0
END) AS email_clicked_rate
FROM
(SELECT
*,
CASE
WHEN action IN ('sent_weekly_digest' , 'sent_reengagement_email') THEN
'email_sent'
WHEN action IN ('email_open') THEN 'email_open'
WHEN action IN ('email_clickthrough') THEN 'email_clicked'
END AS email_cat
FROM
email_events) a;