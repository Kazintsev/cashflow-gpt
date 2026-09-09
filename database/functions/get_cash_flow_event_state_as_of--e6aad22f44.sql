CREATE OR REPLACE FUNCTION public.get_cash_flow_event_state_as_of(p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(event_id bigint, event_date date, event_type text, amount numeric, description text, account_id bigint, liability_id bigint, status text, paid_amount numeric, funded_amount numeric, cash_committed_amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
WITH x AS (
 SELECT e.id,e.event_date,e.event_type,e.amount,e.description,e.account_id,e.liability_id,e.status,
 coalesce(sum(f.amount) FILTER(WHERE f.relation_type='payment' AND t.occurred_at<=p_as_of),0) paid,
 coalesce(sum(f.amount) FILTER(WHERE f.relation_type='funding' AND t.occurred_at<=p_as_of),0) funded,
 coalesce(sum(f.amount) FILTER(WHERE t.occurred_at<=p_as_of AND fa.account_type IN ('bank','cash')),0) committed
 FROM public.cash_flow_events e LEFT JOIN public.cash_flow_event_funding f ON f.cash_flow_event_id=e.id
 LEFT JOIN public.transactions t ON t.id=f.transaction_id LEFT JOIN public.accounts fa ON fa.id=t.from_account_id GROUP BY e.id)
SELECT x.id,x.event_date,x.event_type,x.amount,x.description,x.account_id,x.liability_id,x.status,
 CASE WHEN x.event_type='income' THEN i.received_amount ELSE x.paid END,x.funded,x.committed,
 CASE WHEN x.event_type='income' THEN i.remaining_amount ELSE greatest(x.amount-x.paid,0) END,
 CASE WHEN x.event_type='income' OR x.status='cancelled' OR x.paid>=x.amount THEN 0 ELSE greatest(x.amount-x.committed,0) END,
 CASE WHEN x.event_type='income' THEN i.derived_status WHEN x.status='cancelled' THEN 'cancelled'
 WHEN x.paid>=x.amount THEN 'executed' WHEN x.paid>0 THEN 'partially_executed'
 WHEN x.committed>=x.amount THEN 'secured' WHEN x.committed>0 THEN 'partially_secured' ELSE 'planned' END
FROM x LEFT JOIN public.get_income_event_state_as_of(p_as_of) i ON i.event_id=x.id;
$function$;
