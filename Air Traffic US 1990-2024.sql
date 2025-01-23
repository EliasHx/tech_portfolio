-- In this file, a dataset of over 1 million rows of data on air traffic
-- of the United States (domestic and international) is manipulated to find out
-- how many passenger travel to selected countries in Europe per year


use us_intl_air_traffic;

-- Airport Overview:
-- DE: Frankfurt (FRA), Munich (MUC), Berlin (BER), Düsseldorf (DUS), Hamburg (HAM)
-- FR: Paris Charles de Gaulle (CDG), Paris Orly (ORY), Nice (NCE), Lyon (LYS), Marseille (MRS)
-- NL: Amsterdam (AMS)
-- ES: Madrid (MAD), Barcelona(BCN), Málaga (AGP), Palma de Mallorca (PMI), Alicante (ALC)
-- IT: Rome (FCO), Milan (MXP), Venice (VCE), Naples (NAP), Bologna (BLQ)

-- ------------------------------------------------------ --
-- IMPORTANT:                                             --
-- QUERY WITH WHERE CLAUSE                                -- 
-- TYPE = PASSENGERS TO CROSS OUT FREIGHT AND OTHER TYPES --
-- ------------------------------------------------------ --

SELECT *
FROM   traffic
LIMIT 20;


-- Total passengers per airport per year
SELECT   sum(total) as passengers, usg_apt, fg_apt, `year`
FROM     traffic 
WHERE   fg_apt IN                             -- filtering for these airports
        ('FRA', 'MUC', 'BER', 'DUS', 'HAM',   -- DE
        'CDG', 'ORY', 'NCE', 'LYS', 'MRS',    -- FR
        'AMS',                                -- NL
        'MAD', 'BCN', '', 'PMI', 'ALC',    -- ES
        'FCO', 'MXP', 'VCE', 'NAP', 'BLQ')    -- IT
  AND   type = 'Passengers'
GROUP BY fg_apt, `year`, usg_apt
ORDER BY sum(total) DESC; 


-- Total passengers to all airports per year
SELECT   sum(total) as passengers, `year`
FROM     traffic 
WHERE    fg_apt IN                             -- filtering for these airports
         ('FRA', 'MUC', 'BER', 'DUS', 'HAM',   -- DE
         'CDG', 'ORY', 'NCE', 'LYS', 'MRS',    -- FR
         'AMS',                                -- NL
         'MAD', 'BCN', 'AGP', 'PMI', 'ALC',    -- ES
         'FCO', 'MXP', 'VCE', 'NAP', 'BLQ')    -- IT
   AND   type = 'Passengers'
GROUP BY `year`
ORDER BY passengers DESC;


-- Total passengers per country 
SELECT   SUM(total) as passengers, `year`,
  CASE 
	WHEN fg_apt IN ('FRA', 'MUC', 'BER', 'DUS', 'HAM') THEN 'DE'
	WHEN fg_apt IN ('CDG', 'ORY', 'NCE', 'LYS', 'MRS') THEN 'FR'
	WHEN fg_apt = 'AMS' THEN 'NL'
	WHEN fg_apt IN ('MAD', 'BCN', 'AGP', 'PMI', 'ALC') THEN 'ES'
	WHEN fg_apt IN ('FCO', 'MXP', 'VCE', 'NAP', 'BLQ') THEN 'IT'
  END AS Country
FROM     traffic
WHERE    `year` BETWEEN 2013 AND 2023
  AND    fg_apt IN                             -- filtering for these airports
         ('FRA', 'MUC', 'BER', 'DUS', 'HAM',   -- DE
         'CDG', 'ORY', 'NCE', 'LYS', 'MRS',    -- FR
         'AMS',                                -- NL
         'MAD', 'BCN', 'AGP', 'PMI', 'ALC',    -- ES
         'FCO', 'MXP', 'VCE', 'NAP', 'BLQ')    -- IT
  AND    type = 'Passengers'
GROUP BY `year`, Country
ORDER BY  Country, `year` DESC;


-- Total # of Passengers travelled per year 2013 - 2023
SELECT   sum(total) as passengers, `year`
FROM     traffic 
WHERE    fg_apt IN                             -- filtering for these airports
         ('FRA', 'MUC', 'BER', 'DUS', 'HAM',   -- DE
         'CDG', 'ORY', 'NCE', 'LYS', 'MRS',    -- FR
         'AMS',                                -- NL
         'MAD', 'BCN', 'AGP', 'PMI', 'ALC',    -- ES
         'FCO', 'MXP', 'VCE', 'NAP', 'BLQ')    -- IT
   AND   type = 'Passengers'
   AND   `year` BETWEEN 2013 AND 2023
GROUP BY `year`
ORDER BY  passengers DESC;


-- Where do most flights go?
SELECT   sum(total) AS passengers, fg_apt, `YEAR`
FROM     traffic
WHERE    TYPE = 'Passengers'
  AND    `YEAR`= 2023
GROUP BY `YEAR`, fg_apt
ORDER BY passengers DESC;

