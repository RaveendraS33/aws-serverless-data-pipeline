SELECT
    CASE
        WHEN mag < 2 THEN 'M0-1.9'
        WHEN mag < 4 THEN 'M2-3.9'
        WHEN mag < 5 THEN 'M4-4.9'
        ELSE 'M5+'
    END AS magnitude_bucket,
    count(*) AS quake_count
FROM earthquakes
WHERE dt >= CAST(current_date - interval '30' day AS varchar)
GROUP BY 1
ORDER BY 1;
