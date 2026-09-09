CREATE OR REPLACE FUNCTION public.sync_cash_flow_sources()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_today date:=public.finance_business_date(now());v_from date;v_to date;
BEGIN
 SELECT least(v_today,coalesce(min(event_date),v_today)),
        greatest((v_today+interval '3 months')::date,coalesce(max(event_date),v_today))
 INTO v_from,v_to FROM public.cash_flow_events
 WHERE source_type IN ('rule','bank_schedule') AND status NOT IN ('executed','partially_executed','cancelled');
 PERFORM public.generate_cash_flow_events(v_from,v_to);
 RETURN NULL;
END $function$;
