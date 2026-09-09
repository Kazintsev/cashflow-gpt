CREATE OR REPLACE FUNCTION public.set_credit_card_minimum(p_liability_id bigint, p_amount numeric, p_due_date date)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  l public.liabilities;
  v_period_start date;
  v_candidate date;
  v_prev_month date;
  v_last_day int;
  v_event_id bigint;
  v_source_key text;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
  IF p_amount<=0 THEN RAISE EXCEPTION 'minimum payment must be > 0'; END IF;
  SELECT * INTO l FROM public.liabilities WHERE id=p_liability_id FOR UPDATE;
  IF NOT FOUND OR l.balance_model<>'revolving_account' THEN
    RAISE EXCEPTION 'liability % is not a revolving credit card',p_liability_id;
  END IF;
  IF l.minimum_payment_calculation_day IS NULL THEN
    RAISE EXCEPTION 'minimum_payment_calculation_day is not set for liability %',p_liability_id;
  END IF;

  v_last_day:=EXTRACT(DAY FROM (date_trunc('month',p_due_date)+interval '1 month - 1 day'))::int;
  v_candidate:=make_date(EXTRACT(YEAR FROM p_due_date)::int,EXTRACT(MONTH FROM p_due_date)::int,LEAST(l.minimum_payment_calculation_day,v_last_day));
  IF v_candidate>p_due_date THEN
    v_prev_month:=(date_trunc('month',p_due_date)-interval '1 month')::date;
    v_last_day:=EXTRACT(DAY FROM (date_trunc('month',v_prev_month)+interval '1 month - 1 day'))::int;
    v_period_start:=make_date(EXTRACT(YEAR FROM v_prev_month)::int,EXTRACT(MONTH FROM v_prev_month)::int,LEAST(l.minimum_payment_calculation_day,v_last_day));
  ELSE
    v_period_start:=v_candidate;
  END IF;

  v_source_key:='card_min:'||p_liability_id::text||':'||to_char(p_due_date,'YYYY-MM');

  INSERT INTO public.cash_flow_events(
    event_date,event_type,amount,description,account_id,liability_id,is_planned,is_secured,
    period_start,period_end,calculation_method,living_budget_exempt,status,source_type,source_key,fulfillment_mode
  ) VALUES(
    p_due_date,'debt_payment',p_amount,l.name||' — минимальный платёж',l.linked_account_id,l.id,true,false,
    v_period_start,p_due_date,'bank_calculated_minimum',true,'planned','card_minimum',v_source_key,'cumulative_contributions'
  )
  ON CONFLICT(source_key) WHERE source_key IS NOT NULL DO UPDATE SET
    event_date=EXCLUDED.event_date,amount=EXCLUDED.amount,description=EXCLUDED.description,
    account_id=EXCLUDED.account_id,liability_id=EXCLUDED.liability_id,period_start=EXCLUDED.period_start,
    period_end=EXCLUDED.period_end,calculation_method=EXCLUDED.calculation_method,living_budget_exempt=true,
    source_type='card_minimum',fulfillment_mode='cumulative_contributions'
  RETURNING id INTO v_event_id;

  UPDATE public.liabilities
  SET minimum_payment=p_amount,payment_day=EXTRACT(DAY FROM p_due_date)::smallint
  WHERE id=p_liability_id;

  PERFORM public.reconcile_credit_card_minimum(v_event_id);
  RETURN v_event_id;
END
$function$;
