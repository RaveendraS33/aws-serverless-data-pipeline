SELECT
    event_id,
    event_time,
    mag,
    place,
    latitude,
    longitude,
    depth_km,
    url
FROM earthquakes
WHERE dt >= CAST(current_date - interval '7' day AS varchar)
ORDER BY event_time DESC
LIMIT 100;
