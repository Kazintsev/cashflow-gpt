CREATE OR REPLACE FUNCTION public.refresh_cash_flow()
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 PERFORM public.generate_cash_flow_events(public.finance_business_date(now()),(public.finance_business_date(now())+interval '3 months')::date);
 PERFORM public.refresh_event_security();
END $function$;
