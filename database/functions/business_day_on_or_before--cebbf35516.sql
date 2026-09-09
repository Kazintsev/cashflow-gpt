CREATE OR REPLACE FUNCTION public.business_day_on_or_before(d date)
 RETURNS date
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT CASE EXTRACT(ISODOW FROM d)::int WHEN 6 THEN d-1 WHEN 7 THEN d-2 ELSE d END $function$;
