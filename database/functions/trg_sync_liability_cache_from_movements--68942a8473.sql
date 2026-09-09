CREATE OR REPLACE FUNCTION public.trg_sync_liability_cache_from_movements()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_id bigint;
BEGIN v_id:=CASE WHEN TG_OP='DELETE' THEN OLD.liability_id ELSE NEW.liability_id END; PERFORM public.sync_liability_principal_cache(v_id); IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END $function$;
