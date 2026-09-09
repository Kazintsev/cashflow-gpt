CREATE OR REPLACE FUNCTION public.refresh_event_security()
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$ DECLARE r record;BEGIN FOR r IN SELECT id FROM public.cash_flow_events WHERE status<>'cancelled' LOOP PERFORM public.refresh_cash_flow_event_status(r.id);END LOOP;END $function$;
