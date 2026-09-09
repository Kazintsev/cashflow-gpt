CREATE OR REPLACE FUNCTION public.finance_validate_data_deferred()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;
BEGIN
 SELECT * INTO r FROM public.finance_data_issues() LIMIT 1;
 IF FOUND THEN RAISE EXCEPTION 'finance integrity: %, entity %, details %',r.code,r.entity_id,r.details USING ERRCODE='23514'; END IF;
 RETURN NULL;
END $function$;
