SELECT
    dt,
    regexp_extract(place, '[^,]+$') AS region,
    count(*) AS quake_count,
    max(mag) AS max_mag
FROM earthquakes
WHERE dt >= CAST(current_date - interval '30' day AS varchar)
GROUP BY dt, regexp_extract(place, '[^,]+$')
ORDER BY dt DESC, quake_count DESC;
