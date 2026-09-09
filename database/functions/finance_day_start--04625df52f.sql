CREATE OR REPLACE FUNCTION public.finance_day_start(p_date date)
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT p_date::timestamp AT TIME ZONE public.finance_setting_text('business_timezone','Europe/Moscow') $function$;
