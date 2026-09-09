CREATE OR REPLACE FUNCTION public.get_upcoming_payments(p_days integer DEFAULT 10)
 RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, secured boolean, security_transaction_id bigint, security_note text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 SELECT s.event_id,s.event_date,s.description,s.amount,(s.cash_still_required=0),(SELECT f.transaction_id FROM public.cash_flow_event_funding f JOIN public.transactions t ON t.id=f.transaction_id WHERE f.cash_flow_event_id=s.event_id ORDER BY t.occurred_at DESC,f.id DESC LIMIT 1),CASE WHEN s.cash_still_required=0 THEN 'Деньги уже выведены из свободного cash / платёж обеспечен' WHEN s.cash_committed_amount>0 THEN 'Частично обеспечено; требуется ещё '||s.cash_still_required::text ELSE 'Требуется обеспечить '||s.cash_still_required::text END FROM public.cash_flow_event_state s WHERE s.event_date BETWEEN public.finance_business_date(now()) AND public.finance_business_date(now())+p_days AND s.event_type IN ('expense','debt_payment','planned_expense') AND s.derived_status NOT IN ('cancelled','executed') ORDER BY s.event_date,s.description
$function$;
