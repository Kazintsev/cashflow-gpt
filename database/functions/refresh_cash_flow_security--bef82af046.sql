CREATE OR REPLACE FUNCTION public.refresh_cash_flow_security(p_start date, p_end date)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$ DECLARE r record;n int:=0;BEGIN FOR r IN SELECT id FROM public.cash_flow_events WHERE event_date BETWEEN p_start AND p_end AND status<>'cancelled' LOOP PERFORM public.refresh_cash_flow_event_status(r.id);n:=n+1;END LOOP;RETURN n;END $function$;
