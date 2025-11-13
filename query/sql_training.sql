-- Output the number of movies in each category, sorted descending. ----------

-- START

SELECT 
	F.category_id, C.name , count(F.film_id) as films_count
FROM 
	film_category F 
INNER JOIN 
	category C ON F.category_id = C.category_id
GROUP BY 
	C.name, F.category_id
ORDER BY 
	films_count DESC;
-- END

-- Output the 10 actors whose movies rented the most, sorted in descending order.-----------------------

-- START
WITH film_rental_counts AS (
	SELECT 
		I.film_id, count(R.rental_id) as rental_count
	FROM 
		rental R 
	INNER JOIN 
		inventory I ON R.inventory_id = I.inventory_id
	GROUP BY 
		I.film_id 
	)
SELECT 
	F.actor_id, A.last_name || ' ' || A.first_name as full_name, SUM(R.rental_count) as total_rent_per_actor
FROM 
	film_actor F
INNER JOIN 
	film_rental_counts R ON F.film_id = R.film_id
INNER JOIN 
	actor A ON F.actor_id = A.actor_id
GROUP BY 
	F.actor_id, A.last_name, A.first_name
ORDER BY 
	total_rent_per_actor DESC 
LIMIT 10;
-- END

--  Output the category of movies on which the most money was spent. -------

-- START
SELECT
    C.name,
    SUM(P.amount) AS total_revenue
FROM
    payment P
INNER JOIN
    rental R ON P.rental_id = R.rental_id
INNER JOIN
    inventory I ON R.inventory_id = I.inventory_id
INNER JOIN
    film_category FC ON I.film_id = FC.film_id
INNER JOIN
    category C ON FC.category_id = C.category_id
GROUP BY
    C.name
ORDER BY
    total_revenue DESC
LIMIT 1;
--END 

-- Print the names of movies that are not in the inventory. Write a query without using the IN operator.-----------------

-- START
SELECT 
	 F.film_id, F.title 
FROM 
	inventory I 
RIGHT JOIN 
	film F ON I.film_id = F.film_id
WHERE 
	I.film_id is NULL
ORDER BY title;
-- END

/*
Output the top 3 actors who have appeared the most in movies in the “Children” category.
If several actors have the same number of movies, output all of them.
*/

-- START
WITH children_category AS
(
SELECT film_id 
FROM 
	film_category
WHERE 
	category_id = (
	SELECT
		category_id
	FROM 
		category
	WHERE
		name = 'Children'
	)
),
actor_counts AS (SELECT 
	FA.actor_id, CONCAT(A.last_name,' ',A.first_name) as full_name, count(CC.film_id) as films_count
FROM 
	children_category CC
JOIN 
	film_actor FA ON CC.film_id = FA.film_id
JOIN 
	actor A ON A.actor_id = FA.actor_id
GROUP BY 
	FA.actor_id, A.last_name, A.first_name
)
SELECT 
	full_name, films_count, rank_num
FROM 
	(
	SELECT 
		*, DENSE_RANK() OVER ( ORDER BY films_count DESC) as rank_num
	FROM
		actor_counts
	) AS ranked_actors
WHERE 
	rank_num <= 3
ORDER BY 
	rank_num, full_name;
	
-- END

/*
	Output cities with the number of active and inactive customers (active - customer.active = 1).
	Sort by the number of inactive customers in descending order.
*/

-- START 

SELECT 
	A.city_id , 
	CT.city,
	SUM(CASE WHEN C.active = 1 THEN 1 ELSE 0 END) as active_count, 
	SUM(CASE WHEN C.active = 0 THEN 1 ELSE 0 END) as inactive_count
FROM 
	customer C
JOIN
	address A ON C.address_id = A.address_id
JOIN 
	city CT on CT.city_id = A.city_id
GROUP BY 
	A.city_id, CT.city
ORDER BY 
	inactive_count DESC



-- END

/*
Output the category of movies that have the highest number of total rental hours in the city 
		(customer.address_id in this city) and that start with the letter “a”. 
Do the same for cities that have a “-” in them. Write everything in one query.
*/

-- START 
WITH category_rent_hours AS  ( 
	SELECT
		C.city, Ca.name as category_name,
		SUM(EXTRACT(DAY FROM (R.return_date - rental_date)) * 24 
		+ EXTRACT(HOUR FROM (R.return_date - rental_date)) 
		+ EXTRACT(MINUTE FROM ( R.return_date - rental_date)) /60 )AS total_rent_hours
	FROM 
		rental R
	JOIN 
		customer Cu ON R.customer_id = Cu.customer_id
	JOIN
		address Ad ON Cu.address_id = Ad.address_id
	JOIN 
		city C ON C.city_id = Ad.city_id
	JOIN 
		inventory I ON R.inventory_id = I.inventory_id
	JOIN 
		film_category FC ON FC.film_id = I.film_id
	JOIN  
		category Ca ON Ca.category_id = FC.category_id
	GROUP BY 
		Ca.name, C.city
),
cities_start_with_a AS (

	SELECT 
		'Cities Starting with A' as group_description, city, category_name, total_rent_hours,
		ROW_NUMBER() OVER(ORDER BY total_rent_hours DESC) as rn
	FROM 
		category_rent_hours 
	WHERE 
		city LIKE 'a%' ),
cities_with_dash AS
(
		SELECT 
		'Cities have "-".' as group_description, city, category_name, total_rent_hours,
		ROW_NUMBER() OVER(ORDER BY total_rent_hours DESC) as rn
	FROM 
		category_rent_hours 
	WHERE 
		city LIKE '%-%' 
)

SELECT 
	group_description, city, category_name, total_rent_hours
FROM 
	cities_start_with_a
WHERE
	rn = 1
UNION ALL
SELECT 
	group_description, city, category_name, total_rent_hours
FROM 
	cities_with_dash
WHERE
	rn = 1;
	
-- END 
