-- All comedy movies released between 2000 and 2004, alphabetical

SELECT fi.title,
       fi.release_year
FROM public.film fi
INNER JOIN public.film_category ficat ON ficat.film_id = fi.film_id
INNER JOIN category cat ON cat.category_id = ficat.category_id
WHERE UPPER(cat."name") = 'COMEDY' AND 			-- Filtering only Comedies
 		fi.release_year BETWEEN 2000 AND 2004   -- Filtering by year (from 2000 to 2004)
ORDER BY fi.title


-- Revenue of every rental store for year 2017 (columns: address and address2 - as one column, revenue)

SELECT CONCAT(ad.address, ad.address2) AS addresses,
       SUM(pay.amount) AS revenue
FROM payment pay
INNER JOIN staff ON pay.staff_id = staff.staff_id
INNER JOIN store ON store.store_id = staff.store_id
INNER JOIN address ad ON store.address_id = ad.address_id
GROUP BY CONCAT(ad.address, ad.address2) -- grouping by joined addresses names;

-- Top-3 actors by number of movies they took part in (columns: first_name, last_name, number_of_movies, sorted by-- number_of_movies in descending order)

SELECT ac.first_name,
       ac.last_name,
       COUNT(*) AS number_of_movies
FROM actor ac
INNER JOIN film_actor fa ON ac.actor_id = fa.actor_id
GROUP BY ac.first_name,
         ac.last_name
ORDER BY number_of_movies DESC
FETCH FIRST 3 ROWS WITH TIES;


--TASK 3 but with FETCH
SELECT ac.first_name,
       ac.last_name,
       COUNT(*) AS number_of_movies
FROM actor ac
INNER JOIN film_actor fa ON ac.actor_id = fa.actor_id
GROUP BY ac.first_name,
         ac.last_name
ORDER BY number_of_movies DESC
LIMIT 8;
/* 
SUSAN	DAVIS		54
GINA	DEGENERES	42
WALTER	TORN		41
MARY	KEITEL		40
MATTHEW	CARREY		39
SANDRA	KILMER		37
SCARLETT DAMON		36
UMA	WOOD			35*/

SELECT ac.first_name,
       ac.last_name,
       COUNT(*) AS number_of_movies
FROM actor ac
INNER JOIN film_actor fa ON ac.actor_id = fa.actor_id
GROUP BY ac.first_name,
         ac.last_name
ORDER BY number_of_movies DESC
FETCH FIRST 8 ROWS ONLY;
/*
SUSAN	DAVIS		54
GINA	DEGENERES	42
WALTER	TORN		41
MARY	KEITEL		40
MATTHEW	CARREY		39
SANDRA	KILMER		37
SCARLETT DAMON		36
UMA	WOOD			35*/


SELECT ac.first_name,
       ac.last_name,
       COUNT(*) AS number_of_movies
FROM actor ac
INNER JOIN film_actor fa ON ac.actor_id = fa.actor_id
GROUP BY ac.first_name,
         ac.last_name
ORDER BY number_of_movies DESC
FETCH FIRST 8 ROWS WITH TIES;

/*
SUSAN	DAVIS		54
GINA	DEGENERES	42
WALTER	TORN		41
MARY	KEITEL		40
MATTHEW	CARREY		39
SANDRA	KILMER		37
SCARLETT	DAMON	36
VIVIEN	BASINGER	35
VAL	BOLGER			35
GROUCHO	DUNST		35
HENRY	BERRY		35
UMA	WOOD			35
ANGELA	WITHERSPOON	35*/



-- Number of comedy, horror and action movies per year (columns: release_year, number_of_action_movies,
-- number_of_horror_movies, number_of_comedy_movies), sorted by release year in descending order

SELECT film.release_year,
       SUM(CASE  -- if this is required category, then we will fill it with year, otherwise 0 so that count returns only the number of required categories
                 WHEN UPPER(cat."name") = 'ACTION' THEN film.release_year 
                 ELSE 0
             END) AS number_of_action_movies,
       SUM(CASE
                 WHEN UPPER(cat."name") = 'HORROR' THEN film.release_year
                 ELSE 0
             END) AS number_of_horror_movies,
       SUM(CASE
                 WHEN UPPER(cat."name") = 'COMEDY' THEN film.release_year
                 ELSE 0
             END) AS number_of_comedy_movies
FROM film
INNER JOIN film_category fc ON film.film_id = fc.film_id
INNER JOIN category cat ON fc.category_id = cat.category_id
GROUP BY film.release_year
ORDER BY film.release_year DESC;



-- Which staff members made the highest revenue for each store and deserve a bonus for 2017 year?

/* 		Old version
 * 
SELECT SUM(pay.amount) AS total,
       staff.store_id,
       staff.first_name || ' ' || staff.last_name AS staff_member
FROM staff
INNER JOIN payment pay ON pay.staff_id = staff.staff_id
GROUP BY staff.staff_id,
         staff.store_id
ORDER BY total DESC
LIMIT 2 
*/

-- New version
WITH revenue_cte AS 
    (SELECT s.staff_id,
			s.store_id,
			SUM(p.amount) AS rev_per_staff,
			s.first_name || ' ' || s.last_name AS staff_member -- Concatinating staff memnbers names
	 FROM  payment p 
	 INNER JOIN staff s
	 ON s.staff_id = p.staff_id 	-- Joining tables staff and payment  
	 WHERE date_part('year', p.payment_date) = 2017  -- filtering 
	 GROUP BY s.staff_id), 
max_revenue AS (
	SELECT 	revenue_cte.store_id,
			MAX(revenue_cte.rev_per_staff) AS max_per_store  -- maximal revenue in particular store
	FROM revenue_cte
	GROUP BY revenue_cte.store_id  -- Grouping by store to find max amongst them
) 
SELECT staff_member,
		revenue_cte.rev_per_staff,
		max_revenue.store_id
FROM revenue_cte
INNER JOIN max_revenue
ON max_revenue.max_per_store = revenue_cte.rev_per_staff; -- Joining by comparing revenues



-- Which 5 movies were rented more than others and what's expected audience age for those movies? 
SELECT film.title, 
       CASE 
           WHEN film.rating = 'PG' THEN 'Parental Guidance Suggested' 
           WHEN film.rating = 'PG-13' THEN 'For age over 13'
           WHEN film.rating = 'NC-17' THEN 'For age over 17'
           WHEN film.rating = 'R' THEN 'Under 17 with parents'
           WHEN film.rating = 'G' THEN 'For everybody' 
       END AS rating
FROM rental 
INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id 
INNER JOIN film ON inventory.film_id = film.film_id 
GROUP BY film.title, 
         film.rating 
ORDER BY COUNT(film.title) DESC
FETCH FIRST 5 ROWS WITH TIES;

-- Which actors/actresses didn't act for a longer period of time than others?

WITH maximum AS( -- This and next cte is required to find actors films release years without the film in the most recent year 
	SELECT actor.actor_id, MAX(film.release_year) AS release_year 
	FROM actor
	INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id 
	INNER JOIN film
	ON film_actor.film_id = film.film_id
	GROUP BY actor.actor_id
), years_without_max AS(
	SELECT DISTINCT ON (film.release_year,actor.actor_id) actor.actor_id, film.release_year AS prev_year
	FROM actor
	INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id 
	INNER JOIN film
	ON film_actor.film_id = film.film_id
	LEFT OUTER JOIN maximum
	ON maximum.release_year = film.release_year AND 
		maximum.actor_id = actor.actor_id 
	WHERE maximum IS NULL 
), minimum AS(		-- This and next cte is required to find actors films release years without the film in the first year
	SELECT actor.actor_id, MIN(film.release_year) AS release_year 
	FROM actor
	INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id 
	INNER JOIN film
	ON film_actor.film_id = film.film_id
	GROUP BY actor.actor_id
), years_without_min AS(
	SELECT DISTINCT ON (film.release_year,actor.actor_id) actor.actor_id, film.release_year AS curr_year
	FROM actor
	INNER JOIN film_actor
	ON actor.actor_id = film_actor.actor_id 
	INNER JOIN film
	ON film_actor.film_id = film.film_id
	LEFT OUTER JOIN minimum
	ON minimum.release_year = film.release_year AND 
		minimum.actor_id = actor.actor_id 
	WHERE minimum IS NULL	
), with_diff AS (
		SELECT years_without_min.actor_id, years_without_min.curr_year, years_without_max.prev_year,
		years_without_min.curr_year - years_without_max.prev_year  AS difference
		FROM years_without_max
		INNER JOIN years_without_min
		ON years_without_min.actor_id = years_without_max.actor_id
		WHERE years_without_min.curr_year - years_without_max.prev_year > 0 -- excluding every year, where they are equal or logically not right 
		GROUP BY years_without_min.actor_id, prev_year, curr_year
		ORDER BY years_without_min.actor_id
), final_table AS ( 
	SELECT actor_id, MIN(difference) AS final_diff -- Final table with all right differences between years 
	FROM with_diff
	GROUP BY actor_id, curr_year
) SELECT CONCAT(actor.first_name ,' ',actor.last_name) AS full_name,
		final_diff AS longer_period
	FROM final_table
	INNER JOIN actor
	ON final_table.actor_id  = actor.actor_id 
	WHERE final_diff = (SELECT MAX(final_diff) FROM final_table)




-- Which actors/actresses didn't act for a longer period of time than others?
/* WITH all_years AS
  (SELECT actor.first_name || ' ' || actor.last_name AS full_name,
          film.release_year
   FROM actor
   INNER JOIN film_actor f_a ON f_a.actor_id = actor.actor_id
   INNER JOIN film ON film.film_id = f_a.film_id
   GROUP BY full_name,
            film.release_year
   ORDER BY full_name,
            film.release_year)
SELECT maximal_table.full_name,
       maximal,
       MIN(minimal-maximal) AS result_column
FROM
  (SELECT all_years.full_name,
          all_years.release_year AS minimal
   FROM
     (SELECT DISTINCT ON (1) actor.first_name || ' ' || actor.last_name AS full_name,
                         film.release_year
      FROM actor
      INNER JOIN film_actor fa ON actor.actor_id = fa.actor_id
      INNER JOIN film ON fa.film_id = film.film_id
      GROUP BY full_name,
               film.release_year
      ORDER BY full_name,
               film.release_year) AS minimal_years
   INNER JOIN all_years ON all_years.full_name = minimal_years.full_name
   WHERE all_years.release_year <> minimal_years.release_year --AND all_years.release_year <> maximal_years.max_years

   ORDER BY all_years.full_name,
            all_years.release_year) AS minimal_table
INNER JOIN
  (SELECT all_years.full_name,
          all_years.release_year AS maximal
   FROM
     (SELECT DISTINCT ON (1) actor.first_name || ' ' || actor.last_name AS full_name,
                         film.release_year
      FROM actor
      INNER JOIN film_actor fa ON actor.actor_id = fa.actor_id
      INNER JOIN film ON fa.film_id = film.film_id
      GROUP BY full_name,
               film.release_year
      ORDER BY full_name,
               film.release_year DESC) AS maximal_years
   INNER JOIN all_years ON all_years.full_name = maximal_years.full_name
   WHERE all_years.release_year <> maximal_years.release_year --AND all_years.release_year <> maximal_years.max_years
   ORDER BY all_years.full_name,
            all_years.release_year) AS maximal_table ON minimal_table.full_name = maximal_table.full_name
WHERE (minimal-maximal) > 0
GROUP BY maximal_table.full_name,
         maximal
ORDER BY result_column DESC WITH all_years AS
  (SELECT actor.first_name || ' ' || actor.last_name AS full_name,
          film.release_year
   FROM actor
   INNER JOIN film_actor f_a ON f_a.actor_id = actor.actor_id
   INNER JOIN film ON film.film_id = f_a.film_id
   GROUP BY full_name,
            film.release_year
   ORDER BY full_name,
            film.release_year)
SELECT all_years.full_name,
       all_years.release_year AS minimal
FROM
  (SELECT DISTINCT ON (1) actor.first_name || ' ' || actor.last_name AS full_name,
                      film.release_year
   FROM actor
   INNER JOIN film_actor fa ON actor.actor_id = fa.actor_id
   INNER JOIN film ON fa.film_id = film.film_id
   GROUP BY full_name,
            film.release_year
   ORDER BY full_name,
            film.release_year DESC) AS minimal_years
INNER JOIN all_years ON all_years.full_name = minimal_years.full_name
WHERE all_years.release_year <> minimal_years.release_year --AND all_years.release_year <> maximal_years.max_years

ORDER BY all_years.full_name,
         all_years.release_year */