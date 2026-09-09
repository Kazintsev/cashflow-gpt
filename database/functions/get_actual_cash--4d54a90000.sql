CREATE OR REPLACE FUNCTION public.get_actual_cash(p_as_of date)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT public.get_actual_cash(public.finance_day_end(p_as_of)) $function$;
