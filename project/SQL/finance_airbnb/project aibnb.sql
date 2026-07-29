# Count for item in cell
SELECT estimated_revenue_l365d, COUNT(*) as count
FROM listings
where estimated_revenue_l365d <> '' 
AND (room_type='Hotel room'
and CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 1000)
group by estimated_revenue_l365d
order by estimated_revenue_l365d desc;

#max and min 
select room_type,
MIN(CAST(replace(replace(price,'$',''),',','') as decimal (10,2))) AS minp,
max(cast(replace(replace(price,'$',''),',','') as decimal (10,2))) as maxp,
avg(cast(replace(replace(price,'$',''),',','') as decimal (10,2))) as avgp
from listings
group by room_type;

# Customer Preference
SELECT 
    neighbourhood_cleansed AS loc_neighborhood,
    COUNT(id) AS num_units,
    CAST(AVG(availability_365) AS UNSIGNED) AS y_availability,
    CAST(AVG(accommodates) AS DECIMAL (10,0)) AS accommodates,
	CAST(AVG(review_scores_accuracy) AS DECIMAL (10,2)) AS r_accuracy,
    CAST(AVG(review_scores_cleanliness) AS DECIMAL (10,2)) AS r_clean,
	CAST(AVG(review_scores_communication) AS DECIMAL (10,2)) AS r_communication,
	CAST(AVG(review_scores_location) AS DECIMAL (10,2)) AS r_location,
    CAST((CAST(AVG(reviews_per_month) AS DECIMAL(10,2)) * 12) AS DECIMAL(10,2)) AS Yreview_interactions,
	CAST(AVG(estimated_revenue_l365d) AS DECIMAL(10,2)) AS avg_erevenue,
CASE
    WHEN num_units >= 100 
         AND estimated_revenue >= 30000
         AND review_scores_location >= 4.85
    THEN 'Strong Market'

    WHEN num_units < 10 
         AND estimated_revenue >= 30000
    THEN 'High Potential but Low Sample'

    WHEN estimated_revenue >= 25000 
         AND occupancy >= 220
    THEN 'Good Opportunity'

    ELSE 'Moderate Market'
END AS market_category
FROM listings 
WHERE price IS NOT NULL
    AND estimated_revenue_l365d IS NOT NULL
    AND room_type = 'Entire home/apt' 
    AND CAST(REPLACE(REPLACE(estimated_revenue_l365d, '$', ''), ',', '') AS DECIMAL(10,2))
    AND ((room_type = 'Entire home/apt' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
            OR (room_type = 'Private room' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
            OR (room_type = 'Shared room' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
        )

GROUP BY neighbourhood_cleansed
ORDER BY avg_erevenue DESC;


select neighbourhood_cleansed,price,
room_type,
	estimated_revenue_l365d
from listings
where estimated_revenue_l365d <> ''
and neighbourhood_cleansed = 'Rolling Hills Ranch';


# Focus on room type market - AVG Revenue per year
SELECT
    room_type,
    num_properties,
    occupancy,
    CAST(last_year_revenue /occupancy AS DECIMAL(10,2)) AS efficient_occupancy,
    avg_price_night,
    est_year_revenue,
    last_year_revenue,
    est_year_revenue-last_year_revenue  AS revenue_gap,
    CAST(((est_year_revenue - last_year_revenue) / last_year_revenue) * 100 AS DECIMAL(10,2)) AS expected_growth_percentage,
    CAST((volatility/est_year_revenue) AS DECIMAL (10,2)) AS coeficient_var,
    CAST(est_year_revenue / CAST((volatility/est_year_revenue) AS DECIMAL (10,2)) AS DECIMAL (10,2)) AS risk_adjusted_return
FROM (
    SELECT
        room_type,
        COUNT(*) AS num_properties,
        CAST(AVG(365 - availability_365) AS UNSIGNED) AS occupancy,
        CAST(AVG(CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_price_night,
        CAST(AVG(CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2))) * AVG(365 - availability_365) AS DECIMAL(10,2)) AS est_year_revenue,
        CAST(AVG(CAST(REPLACE(REPLACE(estimated_revenue_l365d,'$',''),',','') AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS last_year_revenue,
        CAST(STDDEV(CAST(REPLACE(REPLACE(estimated_revenue_l365d,'$',''),',','') AS DECIMAL(12,2))) AS DECIMAL(12,2)) AS volatility,
		(CAST(STDDEV(CAST(REPLACE(REPLACE(estimated_revenue_l365d,'$',''),',','') AS DECIMAL(12,2))) AS DECIMAL(12,2))/
        CAST(AVG(CAST(REPLACE(REPLACE(estimated_revenue_l365d,'$',''),',','') AS DECIMAL(12,2))) AS DECIMAL(12,2))) AS coeficient_var
    FROM listings
    WHERE price IS NOT NULL
        AND availability_365 IS NOT NULL
        AND estimated_revenue_l365d IS NOT NULL
        AND room_type <> 'Hotel room'
        AND ((room_type = 'Entire home/apt' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
            OR (room_type = 'Private room' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
            OR (room_type = 'Shared room' AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000)
        )
    GROUP BY room_type
) AS summary
ORDER BY est_year_revenue DESC;




# Customer preference - considering reviews
WITH aggregated_listings AS (
    SELECT 
        neighbourhood_cleansed AS loc_neighborhood,
        COUNT(id) AS num_units,
        CAST(AVG(availability_365) AS UNSIGNED) AS y_availability,
        CAST(AVG(accommodates) AS DECIMAL(10,0)) AS accommodates,
        CAST(AVG(review_scores_accuracy) AS DECIMAL(10,2)) AS r_accuracy,
        CAST(AVG(review_scores_cleanliness) AS DECIMAL(10,2)) AS r_clean,
        CAST(AVG(review_scores_communication) AS DECIMAL(10,2)) AS r_communication,
        CAST(AVG(review_scores_location) AS DECIMAL(10,2)) AS r_location,
        CAST((CAST(AVG(reviews_per_month) AS DECIMAL(10,2)) * 12) AS DECIMAL(10,2)) AS Yreview_interactions,
        CAST(AVG(estimated_revenue_l365d) AS DECIMAL(10,2)) AS avg_erevenue,
        AVG(estimated_revenue_l365d) AS avg_revenue, 
        AVG(availability_365) AS avg_occupancy
    FROM listings 
    WHERE price IS NOT NULL
        AND estimated_revenue_l365d IS NOT NULL
        AND room_type = 'Entire home/apt' 
        AND CAST(REPLACE(REPLACE(estimated_revenue_l365d, '$', ''), ',', '') AS DECIMAL(10,2)) > 0
        AND CAST(REPLACE(REPLACE(price,'$',''),',','') AS DECIMAL(10,2)) <= 10000
    GROUP BY neighbourhood_cleansed
)

SELECT 
    loc_neighborhood,
    num_units,
    y_availability,
    accommodates,
    r_accuracy,
    r_clean,
    r_communication,
    r_location,
    Yreview_interactions,
    avg_erevenue,
    CASE
        WHEN num_units >= 100 
             AND avg_revenue >= 30000
             AND r_location >= 4.85
        THEN 'Strong Market'
        
        WHEN num_units < 10 
             AND avg_revenue >= 30000
        THEN 'High Potential but Low Sample'

        WHEN avg_revenue >= 25000 
             AND avg_occupancy >= 220
        THEN 'Good Opportunity'

        ELSE 'Moderate Market'
    END AS market_category
FROM aggregated_listings
ORDER BY avg_erevenue DESC;