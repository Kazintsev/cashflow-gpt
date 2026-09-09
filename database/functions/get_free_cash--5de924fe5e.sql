CREATE OR REPLACE FUNCTION public.get_free_cash(p_as_of date)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT free_cash_until_next_income FROM public.get_liquidity_until_next_income(public.finance_day_end(p_as_of),NULL) $function$;
