CREATE OR REPLACE FUNCTION public.sync_salary_transaction_to_event()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_old_changed boolean:=false;v_new_changed boolean:=false;
BEGIN
 IF TG_OP IN ('UPDATE','DELETE') AND OLD.income_event_id IS NOT NULL THEN
  IF TG_OP='DELETE' OR NEW.amount IS DISTINCT FROM OLD.amount OR NEW.occurred_at IS DISTINCT FROM OLD.occurred_at OR NEW.income_event_id IS DISTINCT FROM OLD.income_event_id THEN UPDATE public.cash_flow_events SET income_completed_at=NULL WHERE id=OLD.income_event_id;END IF;
  PERFORM public.refresh_cash_flow_event_status(OLD.income_event_id);
 END IF;
 IF TG_OP IN ('INSERT','UPDATE') AND NEW.income_event_id IS NOT NULL THEN PERFORM public.refresh_cash_flow_event_status(NEW.income_event_id); END IF;
 IF TG_OP='UPDATE' THEN
  v_old_changed:=NEW.amount IS DISTINCT FROM OLD.amount OR NEW.salary_period_start IS DISTINCT FROM OLD.salary_period_start OR NEW.salary_component IS DISTINCT FROM OLD.salary_component OR NEW.transaction_type IS DISTINCT FROM OLD.transaction_type;
  v_new_changed:=v_old_changed;
 ELSE v_old_changed:=TG_OP='DELETE';v_new_changed:=TG_OP='INSERT';END IF;
 IF v_old_changed AND OLD.salary_component IN ('advance','vacation') THEN PERFORM public.generate_cash_flow_events(OLD.salary_period_start,(OLD.salary_period_start+interval '2 months')::date);END IF;
 IF v_new_changed AND NEW.salary_component IN ('advance','vacation') THEN PERFORM public.generate_cash_flow_events(NEW.salary_period_start,(NEW.salary_period_start+interval '2 months')::date);END IF;
 RETURN COALESCE(NEW,OLD);
END
$function$;
