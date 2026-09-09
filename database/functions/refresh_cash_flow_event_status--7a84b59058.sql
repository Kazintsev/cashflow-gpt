CREATE OR REPLACE FUNCTION public.refresh_cash_flow_event_status(p_event_id bigint)
 RETURNS cash_flow_events
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v public.cash_flow_events;s record;v_last timestamptz;
BEGIN
 SELECT * INTO v FROM public.cash_flow_events WHERE id=p_event_id FOR UPDATE;
 IF NOT FOUND THEN RETURN NULL; END IF;
 IF v.status='cancelled' THEN RETURN v; END IF;
 SELECT * INTO s FROM public.get_cash_flow_event_state_as_of(now()) WHERE event_id=p_event_id;
 IF v.event_type='income' THEN SELECT last_received_at INTO v_last FROM public.get_income_event_state_as_of(now()) WHERE event_id=p_event_id;
 ELSE SELECT max(t.occurred_at) INTO v_last FROM public.cash_flow_event_funding f JOIN public.transactions t ON t.id=f.transaction_id
 WHERE f.cash_flow_event_id=p_event_id AND f.relation_type='payment' AND t.occurred_at<=now(); END IF;
 UPDATE public.cash_flow_events SET status=s.derived_status,is_secured=(s.cash_still_required=0),security_amount=least(amount,s.cash_committed_amount),
 actual_amount=CASE WHEN s.paid_amount>0 THEN s.paid_amount ELSE NULL END,actual_date=public.finance_business_date(v_last)
 WHERE id=p_event_id RETURNING * INTO v;
 RETURN v;
END
$function$;
