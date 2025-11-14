-- Output the number of movies in each category, sorted descending. ----------

-- START

SELECT 
	f.category_id, 
	c.name, 
	count(f.film_id) as films_count
FROM 
	film_category f
INNER JOIN 
	category c ON f.category_id = c.category_id
GROUP BY 
	c.name, f.category_id
ORDER BY 
	films_count DESC;
-- END

-- Output the 10 actors whose movies rented the most, sorted in descending order.-----------------------

-- START

SELECT 
	a.actor_id,
	CONCAT(a.last_name, ' ', a.first_name),
	COUNT(r.rental_id) as total_rent_per_actor
FROM 
	rental r 
JOIN 
	inventory i ON r.inventory_id = i.inventory_id 
JOIN 
	film_actor fa on fa.film_id = i.film_id 
JOIN 
	actor a ON a.actor_id = fa.actor_id
GROUP BY 
	a.actor_id, a.last_name, a.first_name
ORDER BY 
	total_rent_per_actor DESC
LIMIT 10
	

-- END

--  Output the category of movies on which the most money was spent. -------

-- START
SELECT
    c.name,
    SUM(p.amount) AS total_revenue
FROM
    payment p
INNER JOIN
    rental r ON p.rental_id = r.rental_id
INNER JOIN
    inventory i ON r.inventory_id = i.inventory_id
INNER JOIN
    film_category fc ON i.film_id = fc.film_id
INNER JOIN
    category c ON fc.category_id = c.category_id
GROUP BY
    c.name
ORDER BY
    total_revenue DESC
LIMIT 1;
--END 

-- Print the names of movies that are not in the inventory. Write a query without using the IN operator.-----------------

-- START
SELECT 
	 f.film_id, 
	 f.title 
FROM 
	film f
LEFT JOIN 
	inventory i ON i.film_id = f.film_id
WHERE 
	i.film_id is NULL
ORDER BY title;
-- END

-- START
SELECT 
	f.film_id,
	f.title
FROM 
	film f
WHERE NOT EXISTS (
	SELECT 
		1
	FROM 
		inventory i 
	WHERE 
		f.film_id = i.film_id
);
-- END

/*
Output the top 3 actors who have appeared the most in movies in the “Children” category.
If several actors have the same number of movies, output all of them.
*/
--  1 subquery 🫣
-- START
SELECT 
	actor_id,
	full_name,
	rank_num
	FROM (
	SELECT 
		a.actor_id,
		CONCAT(a.last_name, ' ', a.first_name) as full_name,
		DENSE_RANK() OVER ( ORDER BY COUNT(fc.film_id) DESC) as rank_num
	FROM 
		film_category fc
	JOIN 
		category c ON fc.category_id = c.category_id
	JOIN 
		film_actor fa ON fa.film_id = fc.film_id
	JOIN 
		actor a ON a.actor_id = fa.actor_id
	WHERE 
		c.name = 'Children'
	GROUP BY 
		a.actor_id, a.last_name, a.first_name
)
WHERE 
	rank_num <= 3

-- END

/*
	Output cities with the number of active and inactive customers (active - customer.active = 1).
	Sort by the number of inactive customers in descending order.
*/

-- START 

SELECT 
	a.city_id, 
	ct.city,
	SUM(CASE WHEN c.active = 1 THEN 1 ELSE 0 END) as active_count, 
	SUM(CASE WHEN c.active = 0 THEN 1 ELSE 0 END) as inactive_count
FROM 
	customer c
JOIN
	address a ON c.address_id = a.address_id
JOIN 
	city ct on ct.city_id = a.city_id
GROUP BY 
	a.city_id, ct.city
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
		c.city, 
		ca.name as category_name,
		SUM(EXTRACT(DAY FROM (r.return_date - r.rental_date)) * 24 
		+ EXTRACT(HOUR FROM (r.return_date - r.rental_date)) 
		+ EXTRACT(MINUTE FROM ( r.return_date - r.rental_date)) /60 )AS total_rent_hours
	FROM 
		rental r
	JOIN 
		customer cu ON r.customer_id = cu.customer_id
	JOIN
		address ad ON cu.address_id = ad.address_id
	JOIN 
		city c ON c.city_id = ad.city_id
	JOIN 
		inventory i ON r.inventory_id = i.inventory_id
	JOIN 
		film_category fc ON fc.film_id = i.film_id
	JOIN  
		category ca ON ca.category_id = fc.category_id
	GROUP BY 
		c.city, ca.name

),
cities_starts_with_a AS (

	SELECT 
		'Category in cities with a' as group_description, 
		category_name, 
		SUM(total_rent_hours) as total_rent_hours,
		ROW_NUMBER() OVER(ORDER BY SUM(total_rent_hours) DESC) as rn
	FROM 
		category_rent_hours 
	WHERE 
		category_name ILIKE 'a%' 
	GROUP BY
		category_name
		),
cities_with_dash AS
(
		SELECT 
		'Category in cities with have "-".' as group_description, 
		category_name, 
		SUM(total_rent_hours) as total_rent_hours,
		ROW_NUMBER() OVER(ORDER BY SUM(total_rent_hours) DESC) as rn
	FROM 
		category_rent_hours 
	WHERE 
		city LIKE '%-%' 
	GROUP BY
		category_name
)
SELECT 
	group_description, 
	category_name, 
	total_rent_hours
FROM 
	cities_starts_with_a
WHERE
	rn = 1
UNION ALL
SELECT 
	group_description, 
	category_name, 
	total_rent_hours
FROM 
	cities_with_dash
WHERE
	rn = 1;

-- END
