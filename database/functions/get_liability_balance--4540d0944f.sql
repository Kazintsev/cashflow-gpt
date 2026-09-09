CREATE OR REPLACE FUNCTION public.get_liability_balance(p_liability_id bigint, p_as_of date)
 RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT * FROM public.get_liability_balance(p_liability_id,public.finance_day_end(p_as_of)) $function$;
