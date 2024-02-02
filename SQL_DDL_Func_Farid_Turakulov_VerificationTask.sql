/* Create one function that reports all information for a particular client and timeframe:
• Customer's name, surname and email address;
• Number of films rented during specified timeframe;
• Comma-separated list of rented films at the end of specified time period;
• Total number of payments made during specified time period;
• Total amount paid during specified time period;
Function's input arguments: client_id, left_boundary, right_boundary.
The function must analyze specified timeframe [left_boundary, right_boundary] and output specified information for this timeframe.
Function's result format: table with 2 columns ‘metric_name’ and ‘metric_value’.
*/

CREATE OR REPLACE FUNCTION get_client_info(IN i_client_id INT, IN left_boundary TIMESTAMP, IN right_boundary TIMESTAMP)
RETURNS TABLE(metric_name TEXT, metric_value TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY WITH all_info AS(
		SELECT c.first_name, c.last_name ,c.email, r.rental_id, f.title, p.customer_id, p.amount
		FROM public.customer c
		INNER JOIN public.rental r 
		ON r.customer_id = c.customer_id 
		INNER JOIN public.inventory i
		ON r.inventory_id = i.inventory_id 
		INNER JOIN public.film f
		ON f.film_id = i.film_id 
		INNER JOIN public.payment p 
		ON p.rental_id = r.rental_id 
		WHERE c.customer_id = i_client_id AND 
		r.rental_date >= left_boundary AND
		r.rental_date <= right_boundary)
	SELECT DISTINCT  E'customer\'s info' AS metric_name,CONCAT(first_name, ' ', last_name,', ',email) AS metric_value	
	FROM all_info a
	UNION ALL
	SELECT DISTINCT 'num. of films rented' AS metric_name, CAST(COUNT(a.title) AS TEXT) AS metric_value	
	FROM all_info a 
	GROUP BY title
	UNION ALL 
	SELECT E'rented films\' titles' AS metric_name, string_agg(DISTINCT title, ', ') AS metric_value
	FROM all_info a
	UNION ALL 
	SELECT 'num. of payments' AS metric_name, CAST(COUNT(a.customer_id)AS TEXT) AS metric_value
	FROM all_info a
	GROUP BY a.customer_id
	UNION ALL 
	SELECT E'payments\' amount ' AS metric_name, CAST(SUM(a.amount)AS TEXT) AS metric_value
	FROM all_info a
	GROUP BY a.customer_id;
END;	
$$;

SELECT * FROM get_client_info(123,'2004-05-25 00:54:33.000 +0500','2010-05-25 00:54:33.000 +0500')

