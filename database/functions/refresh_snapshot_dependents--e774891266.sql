CREATE OR REPLACE FUNCTION public.refresh_snapshot_dependents()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;
BEGIN
 IF TG_TABLE_NAME='account_balance_snapshots' THEN
  FOR r IN SELECT id FROM public.liabilities WHERE linked_account_id IN (CASE WHEN TG_OP<>'INSERT' THEN OLD.account_id END,CASE WHEN TG_OP<>'DELETE' THEN NEW.account_id END) LOOP PERFORM public.sync_liability_principal_cache(r.id);END LOOP;
 ELSE
  IF TG_OP<>'INSERT' THEN PERFORM public.sync_liability_principal_cache(OLD.liability_id); END IF;
  IF TG_OP<>'DELETE' THEN PERFORM public.sync_liability_principal_cache(NEW.liability_id); END IF;
 END IF;
 RETURN COALESCE(NEW,OLD);
END $function$;
