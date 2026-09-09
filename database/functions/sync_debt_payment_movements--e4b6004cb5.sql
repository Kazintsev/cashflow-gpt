CREATE OR REPLACE FUNCTION public.sync_debt_payment_movements()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 IF TG_OP IN ('UPDATE','DELETE') THEN
  DELETE FROM public.liability_movements WHERE debt_payment_detail_id=OLD.id;
  PERFORM public.rebuild_debt_payment_movements(OLD.liability_id);
 END IF;
 IF TG_OP='INSERT' OR (TG_OP='UPDATE' AND NEW.liability_id IS DISTINCT FROM OLD.liability_id) THEN PERFORM public.rebuild_debt_payment_movements(NEW.liability_id); END IF;
 RETURN COALESCE(NEW,OLD);
END
$function$;
