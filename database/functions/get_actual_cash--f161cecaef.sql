CREATE OR REPLACE FUNCTION public.get_actual_cash(p_as_of timestamp with time zone DEFAULT now())
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT COALESCE(SUM(public.get_account_balance(a.id,p_as_of)),0) FROM public.accounts a WHERE a.is_active AND a.account_type IN ('bank','cash') $function$;
