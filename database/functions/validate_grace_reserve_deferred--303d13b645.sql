CREATE OR REPLACE FUNCTION public.validate_grace_reserve_deferred()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 IF EXISTS(WITH r AS (SELECT reserve_liability_id,reserve_cycle,occurred_at,id,sum(CASE reserve_effect WHEN 'grace_draw' THEN amount ELSE -amount END) OVER(PARTITION BY reserve_liability_id,reserve_cycle ORDER BY occurred_at,id) outstanding FROM public.transactions WHERE reserve_effect<>'none') SELECT 1 FROM r WHERE outstanding<0) THEN RAISE EXCEPTION 'grace repayments exceed preceding draws';END IF;
 RETURN NULL;
END $function$;
