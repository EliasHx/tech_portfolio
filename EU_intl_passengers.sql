USE eu_intl_passengers;

SELECT *
FROM passengers;



-- Departing Spain
SELECT * 
FROM   passengers 
WHERE  departure_country = 'ES'       -- filter to country
  AND  `year` BETWEEN 2013 AND 2023   -- filter most recent years
 -- AND  thou_passengers IS NOT NULL    -- filter out null values (no connections/no data)
ORDER BY arrival_country DESC;

-- Departing France
SELECT * 
FROM   passengers 
WHERE  departure_country = 'FR'
  AND  `year` BETWEEN 2013 AND 2023
  AND  thou_passengers IS NOT NULL
ORDER BY arrival_country DESC;

-- Departing Germany
SELECT * 
FROM   passengers 
WHERE  departure_country = 'DE'
  AND  `year` BETWEEN 2013 AND 2023
  AND  thou_passengers IS NOT NULL
ORDER BY thou_passengers DESC;

-- Departing Netherlands
SELECT * 
FROM   passengers 
WHERE  departure_country = 'NL'
  AND  `year` BETWEEN 2013 AND 2023
  AND  thou_passengers IS NOT NULL
ORDER BY arrival_country DESC;

-- Departing Italy
SELECT * 
FROM   passengers 
WHERE  departure_country = 'IT'
  AND  `year` BETWEEN 2013 AND 2023
  AND  thou_passengers IS NOT NULL
ORDER BY arrival_country DESC;


-- combining all countries
SELECT * 
FROM   passengers 
WHERE  departure_country IN ('DE', 'ES', 'FR', 'IT', 'NL')
  AND  `year` BETWEEN 2013 AND 2023
  AND  thou_passengers IS NOT NULL
ORDER BY thou_passengers DESC;


-- sum traveled FROM a country by year
SELECT   departure_country, SUM(thou_passengers) * 1000 AS Outgoing_Passengers, `year`
FROM     passengers 
WHERE    departure_country IN ('DE', 'ES', 'FR', 'IT', 'NL')
  AND    `year` BETWEEN 2013 AND 2023
  AND    thou_passengers IS NOT NULL
GROUP BY `year`, departure_country
ORDER BY  departure_country, `year` DESC;


-- sum traveled TO a country by year
SELECT   arrival_country, SUM(thou_passengers)*1000 AS Incoming_Passengers, `year`
FROM     passengers 
WHERE    arrival_country IN ('DE', 'ES', 'FR', 'IT', 'NL')
  AND    `year` BETWEEN 2013 AND 2023
  AND    thou_passengers IS NOT NULL
GROUP BY `year`, arrival_country
ORDER BY  arrival_country, `year` DESC;


-- Total Number of passengers
SELECT   SUM(thou_passengers * 1000) as passengers, `year`
FROM     passengers
WHERE    arrival_country IN ('DE', 'ES', 'FR', 'IT', 'NL')
  AND    `year` BETWEEN 2013 AND 2023
  AND    thou_passengers IS NOT NULL
GROUP BY `year`
ORDER BY passengers DESC;




