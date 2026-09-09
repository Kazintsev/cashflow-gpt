CREATE OR REPLACE FUNCTION public.finance_business_date(p_ts timestamp with time zone DEFAULT now())
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT (p_ts AT TIME ZONE public.finance_setting_text('business_timezone','Europe/Moscow'))::date $function$;
