CREATE OR REPLACE FUNCTION public.trg_sync_revolving_liability_cache()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;
BEGIN
 FOR r IN SELECT DISTINCT l.id FROM public.liabilities l WHERE l.balance_model='revolving_account' AND (l.linked_account_id=COALESCE(NEW.from_account_id,OLD.from_account_id) OR l.linked_account_id=COALESCE(NEW.to_account_id,OLD.to_account_id) OR (TG_OP='UPDATE' AND (l.linked_account_id=OLD.from_account_id OR l.linked_account_id=OLD.to_account_id))) LOOP PERFORM public.sync_liability_principal_cache(r.id); END LOOP;
 IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END $function$;
