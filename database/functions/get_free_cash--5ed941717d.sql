CREATE OR REPLACE FUNCTION public.get_free_cash(p_as_of timestamp with time zone DEFAULT now())
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT free_cash_until_next_income FROM public.get_liquidity_until_next_income(p_as_of,NULL) $function$;
