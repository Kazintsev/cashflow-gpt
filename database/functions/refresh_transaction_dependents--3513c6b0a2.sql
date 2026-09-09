CREATE OR REPLACE FUNCTION public.refresh_transaction_dependents()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;
BEGIN
 IF TG_OP='UPDATE' AND NEW.occurred_at IS DISTINCT FROM OLD.occurred_at THEN
  FOR r IN SELECT DISTINCT liability_id FROM public.debt_payment_details WHERE transaction_id=NEW.id LOOP PERFORM public.rebuild_debt_payment_movements(r.liability_id); END LOOP;
 END IF;
 IF TG_OP='UPDATE' THEN
  FOR r IN SELECT DISTINCT cash_flow_event_id FROM public.cash_flow_event_funding WHERE transaction_id=NEW.id LOOP PERFORM public.refresh_cash_flow_event_status(r.cash_flow_event_id); END LOOP;
 END IF;
 RETURN COALESCE(NEW,OLD);
END $function$;
