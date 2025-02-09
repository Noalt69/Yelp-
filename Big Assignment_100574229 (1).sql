-- Answers to Big Assignment, student number: 100574229
-- Question1

SELECT 
    CASE 
        WHEN stars >= 4.5 THEN 'Excellent_rating'
        WHEN stars >= 3 AND stars < 4.5 THEN 'Good_rating'
        WHEN stars >= 2 AND stars < 3 THEN 'Poor_rating'
        WHEN stars < 2 THEN 'Very_poor_rating'
    END AS rating_level,
    AVG(review_count) AS average_review_count
FROM business
WHERE active = 'true'
GROUP BY rating_level;

-- Question2

SELECT u.name, f.friend_count AS amount_of_friends
FROM (
    SELECT user_id1 AS user_id, COUNT(DISTINCT user_id2) AS friend_count
    FROM friends
    GROUP BY user_id1
    ORDER BY friend_count DESC
    LIMIT 1
) AS f
JOIN users u ON f.user_id = u.user_id;

-- Question3

-- Part a
SELECT city, SUM(review_count) AS total_reviews
FROM business
GROUP BY city
HAVING SUM(review_count) < 100000
ORDER BY total_reviews DESC
LIMIT 1;

-- Part b
SELECT bc.category AS business_category, SUM(b.review_count) AS total_reviews
FROM business b
JOIN business_categories bc ON b.business_id = bc.business_id
WHERE b.city = 'Phoenix'
GROUP BY bc.category
ORDER BY total_reviews DESC
LIMIT 1;

-- Question4

-- Find user with the highest number of fans
SELECT u.user_id, 
       u.name AS user_name, 
       u.fans
FROM users u
ORDER BY u.fans DESC
LIMIT 1;

-- Funny ranking determination
SELECT u.name AS user_name,
       u.fans,
       u.votes_funny,
       RANK() OVER (ORDER BY u.votes_funny DESC) AS funny_votes_rank
FROM users u
WHERE u.user_id = (SELECT user_id 
                   FROM users 
                   ORDER BY fans DESC 
                   LIMIT 1);


-- Question5

-- Part a
SELECT COUNT(*)
FROM users
WHERE yelping_since_year = 2010 AND yelping_since_month >= 9
   OR yelping_since_year = 2011 AND yelping_since_month <= 5
   AND votes_funny = 0 AND votes_useful = 0 AND votes_cool = 0;

-- Part b
SELECT u.name, u.review_count
FROM users u
JOIN (
    SELECT r.user_id
    FROM reviews r
    JOIN business b ON r.business_id = b.business_id
    WHERE b.city = 'Phoenix'
    GROUP BY r.user_id
) AS phoenix_reviewers ON u.user_id = phoenix_reviewers.user_id
ORDER BY u.review_count DESC
LIMIT 1;


-- Question6

SELECT b.business_name, bh.opening_time
FROM business b
JOIN business_attributes_goodfor bag ON b.business_id = bag.business_id
JOIN business_hours bh ON b.business_id = bh.business_id
WHERE b.active = 'true'
  AND b.stars = 5
  AND bag.subattribute = 'breakfast'
  AND bag.value = 'true'
  AND bh.day_of_week = 'Sunday'
LIMIT 1;

-- Question7

SELECT b.business_name, 
       (SUM(CASE WHEN r.stars > 4 THEN 1 ELSE 0 END) / COUNT(r.review_id)) AS high_rating_ratio
FROM reviews r
JOIN business b ON r.business_id = b.business_id
GROUP BY b.business_id, b.business_name
HAVING COUNT(r.review_id) > 800
ORDER BY high_rating_ratio DESC
LIMIT 1;

-- Question8

SELECT b.business_name, 
       b.stars AS star_rating,
       SUM(c.time_18 + c.time_19 + c.time_20 + c.time_21 + c.time_22 + c.time_23) AS total_checkins
FROM checkins c
JOIN business b ON c.business_id = b.business_id
JOIN business_categories bc ON b.business_id = bc.business_id
WHERE c.day_of_week = 'Monday'
  AND b.active = 'true'
  AND bc.category = 'Hotels'
GROUP BY b.business_id, b.business_name, b.stars
ORDER BY total_checkins DESC, b.stars DESC
LIMIT 3;

-- Question9

SELECT 
    CASE 
        WHEN specialization_count >= 7 THEN 'Full_specialities'
        WHEN specialization_count = 5 OR specialization_count = 6 THEN 'Multiple_specialities'
        WHEN specialization_count = 3 OR specialization_count = 4 THEN 'Some_specialities'
        WHEN specialization_count = 1 OR specialization_count = 2 THEN 'Few_specialities'
    END AS speciality_category,
    AVG(b.stars) AS average_stars
FROM (
    SELECT bah.business_id, COUNT(*) AS specialization_count
    FROM business_attributes_hairtypesspecializedin bah
    WHERE bah.value = 'true'
    GROUP BY bah.business_id
) AS specialization_counts
JOIN business b ON specialization_counts.business_id = b.business_id
GROUP BY speciality_category;
ORDER BY FIELD(speciality_category, 'full_specialities', 'multiple_specialities', 'some_specialities', 'few_specialities');

-- Question10
 
WITH CleanedTips AS (
    SELECT LOWER(
           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tip_text, '"', ''), '“', ''), '”', ''), '-', ''), ',', ''), '!', ''), '`', '')
           ) AS cleaned_text
    FROM tips
    WHERE LENGTH(TRIM(tip_text)) - LENGTH(REPLACE(TRIM(tip_text), ' ', '')) >= 1  -- Ensures at least two words
),
FirstSecondWordCounts AS (
    SELECT 
        COUNT(CASE WHEN SUBSTRING_INDEX(cleaned_text, ' ', 1) = 'food' THEN 1 END) AS food_as_first,
        COUNT(CASE WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_text, ' ', 2), ' ', -1) = 'food' 
                   AND SUBSTRING_INDEX(cleaned_text, ' ', 1) != 'food' THEN 1 END) AS food_as_second
    FROM CleanedTips
),
MostCommonFirstWord AS (
    SELECT SUBSTRING_INDEX(cleaned_text, ' ', 1) AS first_word,
           COUNT(*) AS frequency
    FROM CleanedTips
    WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_text, ' ', 2), ' ', -1) = 'food'
    GROUP BY first_word
    ORDER BY frequency DESC
    LIMIT 1
)
-- Output
SELECT 
    fsc.food_as_first AS "The word 'Food' as 1st word",
    fsc.food_as_second AS "The word 'Food' as 2nd word",
    mcfw.first_word AS "Most popular first word with 'food' as second word",
    mcfw.frequency AS "Frequency of the word"
FROM FirstSecondWordCounts fsc, MostCommonFirstWord mcfw;


-- Question11

WITH reviews_by_year AS (
    SELECT 
        business_id,
        YEAR(review_date) AS review_year,
        COUNT(review_id) AS total_reviews
    FROM reviews
    WHERE YEAR(review_date) IN (2012, 2013)
    GROUP BY business_id, review_year
),
review_diff AS (
    SELECT 
        r2012.business_id,
        b.business_name,
        r2012.total_reviews AS reviews_2012,
        r2013.total_reviews AS reviews_2013,
        (r2012.total_reviews - COALESCE(r2013.total_reviews, 0)) AS review_difference
    FROM reviews_by_year r2012
    LEFT JOIN reviews_by_year r2013 ON r2012.business_id = r2013.business_id AND r2013.review_year = 2013
    JOIN business b ON r2012.business_id = b.business_id
    WHERE r2012.review_year = 2012
)
SELECT 
    business_name, 
    review_difference
FROM review_diff
ORDER BY review_difference DESC
LIMIT 1;

-- Question12

-- Create a temporary table to select reviews from 2012
WITH reviews_2012 AS (
    SELECT 
        r.review_id, 
        r.user_id, 
        r.business_id, 
        r.stars, 
        r.review_date
    FROM reviews r
    WHERE YEAR(r.review_date) = 2012
),

-- Filter valid reviews where users did not submit multiple reviews for the same business on the same day
valid_reviews AS (
    SELECT 
        rwc.user_id, 
        rwc.business_id, 
        rwc.review_date, 
        rwc.stars
    FROM (
        SELECT 
            r2012.user_id, 
            r2012.business_id, 
            r2012.review_date, 
            r2012.stars,
            COUNT(r2012.review_id) OVER (PARTITION BY r2012.user_id, r2012.business_id, r2012.review_date) AS review_count
        FROM reviews_2012 r2012
    ) AS rwc
    WHERE rwc.review_count = 1
),

-- Rank user visits to the same business by review date
ranked_visits AS (
    SELECT 
        vr.user_id, 
        vr.business_id, 
        vr.stars, 
        vr.review_date,
        RANK() OVER (PARTITION BY vr.user_id, vr.business_id ORDER BY vr.review_date) AS visit_rank
    FROM valid_reviews vr
)

-- Count users who rated a business higher on a subsequent visit
SELECT 
    COUNT(DISTINCT rv1.user_id) AS user_count
FROM ranked_visits rv1
JOIN ranked_visits rv2 
    ON rv1.user_id = rv2.user_id 
    AND rv1.business_id = rv2.business_id
WHERE rv1.visit_rank = 1 
  AND rv2.visit_rank > 1
  AND rv2.stars > rv1.stars;





