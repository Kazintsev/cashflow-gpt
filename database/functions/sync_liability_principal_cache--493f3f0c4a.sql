CREATE OR REPLACE FUNCTION public.sync_liability_principal_cache(p_liability_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_p numeric;
BEGIN SELECT principal_balance INTO v_p FROM public.get_liability_balance(p_liability_id,now()); IF v_p IS NOT NULL THEN UPDATE public.liabilities SET principal_current=v_p WHERE id=p_liability_id; END IF; END $function$;
