CREATE OR REPLACE FUNCTION public.refresh_cash_flow_event_from_allocation()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    PERFORM public.refresh_cash_flow_event_status(OLD.cash_flow_event_id);
  END IF;
  IF TG_OP IN ('INSERT','UPDATE') THEN
    PERFORM public.refresh_cash_flow_event_status(NEW.cash_flow_event_id);
  END IF;
  RETURN COALESCE(NEW,OLD);
END
$function$;
