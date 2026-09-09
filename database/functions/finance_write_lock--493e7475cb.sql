CREATE OR REPLACE FUNCTION public.finance_write_lock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 IF current_setting('transaction_isolation')='repeatable read' THEN RAISE EXCEPTION 'Finance writes require READ COMMITTED or SERIALIZABLE'; END IF;
 PERFORM pg_advisory_xact_lock(20260905,731);
 RETURN NULL;
END $function$;
