USE H_Furniture;

-- test product table
SELECT * 
from   Product p 
LIMIT 50;

-- test review table
SELECT *
FROM   review
LIMIT 50;

-- test price table
SELECT *
FROM   price
LIMIT 50;


-- Creating JOINS of product, price, and reviews for the case question
SELECT    p.product_id, p.sku, p.product_name,
		  pr.original_price, pr.discounted_price, pr.black_friday_deal,
		  r.five_star, r.four_star, r.three_star, r.two_star, r.one_star
FROM      product AS p
LEFT JOIN price AS pr USING(price_id)    -- left join to include potential null values
LEFT JOIN review AS r USING(review_id)   -- left join to include potential null values
WHERE     ;


-- avg review score per product
SELECT    p.product_id, p.product_name,
	      SUM((r.five_star * 5) + (r.four_star * 4) + (r.three_star * 3) +    -- collecting review sum
	          (r.two_star * 2) + (r.one_star * 1)) / 
	      -- deviding by count of review
          NULLIF(SUM(r.five_star + r.four_star + r.three_star + r.two_star + r.one_star), 0) AS avg_review_score
FROM      product p
LEFT JOIN review r      -- left joining review on product
    USING(review_id)
GROUP BY  p.product_id, p.product_name;



-- Discount per product
SELECT    p.product_id, p.product_name,
		  -- calculating % of discount
		  ROUND(((pr.original_price - pr.discounted_price) / pr.original_price) * 100, 2) AS pct_discount
FROM      product as p
LEFT JOIN price as pr    -- left joining price on product
    USING(price_id)
-- WHERE     pr.black_friday_deal = 1;
    
    
-- Combining all queries
SELECT    p.product_id, p.sku, p.product_name,
		  pr.original_price, pr.discounted_price, 
		  -- calculating discount in %
		  ROUND(((pr.original_price - pr.discounted_price) / pr.original_price) * 100, 2) AS pct_discount,
		  pr.black_friday_deal,
		  -- collecting review sum
		  SUM((r.five_star * 5) + (r.four_star * 4) + (r.three_star * 3) +
	          (r.two_star * 2) + (r.one_star * 1)) / 
	      -- deviding by count of review
          NULLIF(SUM(r.five_star + r.four_star + r.three_star + r.two_star + r.one_star), 0) AS avg_review_score,
		  r.five_star, r.four_star, r.three_star, r.two_star, r.one_star
FROM      product AS p
LEFT JOIN price AS pr USING(price_id)    -- left join to include potential null values
LEFT JOIN review AS r USING(review_id)   -- left join to include potential null values
GROUP BY  p.product_id, p.product_name,
		  pr.original_price, pr.discounted_price
;


-- ------------------ --
-- ------------------ --
-- THE ULTIMATE TABLE --
-- ------------------ --
-- ------------------ --

-- JOIN every table
SELECT    p.product_id, p.sku, p.product_name,
          b.brand_name,
          c.category,
          sc.subcategory,
		  pr.original_price, pr.discounted_price, 
		  -- calculating discount in %
		  ROUND(((pr.original_price - pr.discounted_price) / pr.original_price) * 100, 2) AS pct_discount,
		  pr.black_friday_deal,
		  -- collecting review sum
		  SUM((r.five_star * 5) + (r.four_star * 4) + (r.three_star * 3) +
	          (r.two_star * 2) + (r.one_star * 1)) / 
	      -- deviding by count of review
          NULLIF(SUM(r.five_star + r.four_star + r.three_star + r.two_star + r.one_star), 0) AS avg_review_score,
		  r.five_star, r.four_star, r.three_star, r.two_star, r.one_star,
		  co.listed_color,
		  s.height, s.width, s.`depth`, s.one_size, s.measurement_units, s.notes
FROM      product     AS p
LEFT JOIN price       AS pr USING(price_id)                          -- left join price
LEFT JOIN review      AS r  USING(review_id)                         -- left join review
LEFT JOIN procat      AS pc ON p.product_id = pc.product_id          -- left join procat on products for category
LEFT JOIN category    AS c  ON pc.category_id = c.category_id        -- left join category on procat
LEFT JOIN catsub      AS cs ON p.product_id = cs.product_id          -- left join catsub on products for subcategory
LEFT JOIN subcategory AS sc ON cs.subcategory_id = sc.subcategory_id  -- left join subcategory on catsub
LEFT JOIN color       AS co USING(color_id)
LEFT JOIN brand       AS b  USING(brand_id)
LEFT JOIN `size`      AS s  USING(size_id)
GROUP BY  p.product_id, p.product_name,
          b.brand_name,
          c.category,
		  sc.subcategory,
		  pr.original_price, pr.discounted_price,
		  co.listed_color,
		  s.height, s.width, s.`depth`, s.one_size, s.measurement_units, s.notes;
	
		 
		 
		 
-- Testing results with controling query

SELECT    COUNT(DISTINCT co.listed_color)
FROM      product     AS p
LEFT JOIN price       AS pr USING(price_id)                          -- left join price
LEFT JOIN review      AS r  USING(review_id)                         -- left join review
LEFT JOIN procat      AS pc ON p.product_id = pc.product_id          -- left join procat on products for category
LEFT JOIN category    AS c  ON pc.category_id = c.category_id        -- left join category on procat
LEFT JOIN catsub      AS cs ON p.product_id = cs.product_id          -- left join catsub on products for subcategory
LEFT JOIN subcategory AS sc ON cs.subcategory_id = sc.subcategory_id -- left join subcategory on catsub
LEFT JOIN color       AS co USING(color_id)
LEFT JOIN brand       AS b  USING(brand_id)
LEFT JOIN `size`      AS s  USING(size_id)
WHERE     pr.black_friday_deal = 1


-- % discount to avg_review_score per category
SELECT    c.category, COUNT(*),
          ROUND(((pr.original_price - pr.discounted_price) / pr.original_price) * 100, 2) AS pct_discount,
		  -- collecting review sum
		  SUM((r.five_star * 5) + (r.four_star * 4) + (r.three_star * 3) +
	          (r.two_star * 2) + (r.one_star * 1)) / 
	      -- deviding by count of review
          NULLIF(SUM(r.five_star + r.four_star + r.three_star + r.two_star + r.one_star), 0) AS avg_review_score
FROM      product     AS p
LEFT JOIN price       AS pr USING(price_id)                          -- left join price
LEFT JOIN review      AS r  USING(review_id)                         -- left join review
LEFT JOIN procat      AS pc ON p.product_id = pc.product_id          -- left join procat on products for category
LEFT JOIN category    AS c  ON pc.category_id = c.category_id        -- left join category on procat
LEFT JOIN catsub      AS cs ON p.product_id = cs.product_id          -- left join catsub on products for subcategory
LEFT JOIN subcategory AS sc ON cs.subcategory_id = sc.subcategory_id -- left join subcategory on catsub
LEFT JOIN color       AS co USING(color_id)
LEFT JOIN brand       AS b  USING(brand_id)
LEFT JOIN `size`      AS s  USING(size_id)
WHERE     pr.black_friday_deal = 1
GROUP BY  c.category, pct_discount
ORDER BY  pct_discount DESC;


SELECT (SELECT COUNT(*)
        FROM furniture_df
        WHERE review_score = 0) AS no_score,
       (SELECT COUNT(*)
        FROM furniture_df
        WHERE review_score BETWEEN 3 AND 4) AS 3-4_score,
       (SELECT COUNT(*)
        FROM furniutre_df
        WHERE review_score BETWEEN 4 AND 5) AS 4-5_score,
        (SELECT COUNT(*)
        FROM furniture_df
        WHERE review_score = 5) AS 5_score
FROM furniture_df
LEFT JOIN price       AS pr USING(price_id)                          -- left join price
LEFT JOIN review      AS r  USING(review_id)                         -- left join review
LEFT JOIN procat      AS pc ON p.product_id = pc.product_id          -- left join procat on products for category
LEFT JOIN category    AS c  ON pc.category_id = c.category_id        -- left join category on procat
LEFT JOIN catsub      AS cs ON p.product_id = cs.product_id          -- left join catsub on products for subcategory
LEFT JOIN subcategory AS sc ON cs.subcategory_id = sc.subcategory_id -- left join subcategory on catsub
LEFT JOIN color       AS co USING(color_id)
LEFT JOIN brand       AS b  USING(brand_id)
LEFT JOIN `size`      AS s  USING(size_id);


