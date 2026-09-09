CREATE OR REPLACE FUNCTION public.get_income_event_state_as_of(p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(event_id bigint, received_amount numeric, remaining_amount numeric, derived_status text, last_received_at timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 WITH a AS (
 SELECT e.id,e.amount,e.status,e.income_completed_at,coalesce(sum(t.amount) FILTER(WHERE t.occurred_at<=p_as_of),0) received,
 max(t.occurred_at) FILTER(WHERE t.occurred_at<=p_as_of) last_at
 FROM public.cash_flow_events e LEFT JOIN public.transactions t ON t.income_event_id=e.id AND t.transaction_type='income'
 WHERE e.event_type='income' GROUP BY e.id)
 SELECT id,received,CASE WHEN status='cancelled' OR income_completed_at<=p_as_of THEN 0 ELSE greatest(amount-received,0) END,
 CASE WHEN status='cancelled' THEN 'cancelled' WHEN received>=amount OR income_completed_at<=p_as_of THEN 'executed'
 WHEN received>0 THEN 'partially_executed' ELSE 'planned' END,last_at FROM a;
$function$;
