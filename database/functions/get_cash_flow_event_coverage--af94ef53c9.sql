CREATE OR REPLACE FUNCTION public.get_cash_flow_event_coverage(p_event_id bigint)
 RETURNS TABLE(planned_amount numeric, paid_amount numeric, funded_amount numeric, remaining_payment_amount numeric, remaining_funding_amount numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
SELECT s.amount,s.paid_amount,s.funded_amount,s.remaining_payment_amount,s.cash_still_required
FROM public.get_cash_flow_event_state_as_of(now()) s WHERE s.event_id=p_event_id;
$function$;
