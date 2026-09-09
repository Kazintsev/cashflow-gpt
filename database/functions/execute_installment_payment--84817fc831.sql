CREATE OR REPLACE FUNCTION public.execute_installment_payment(p_event_id bigint, p_occurred_at timestamp with time zone DEFAULT now(), p_actual_amount numeric DEFAULT NULL::numeric, p_principal_amount numeric DEFAULT NULL::numeric, p_interest_amount numeric DEFAULT NULL::numeric, p_fee_amount numeric DEFAULT NULL::numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  e public.cash_flow_events;
  l public.liabilities;
  s public.liability_payment_schedule;
  v_amount numeric;
  v_principal numeric;
  v_interest numeric;
  v_fee numeric;
  v_balance numeric;
  v_tx_id bigint;
  v_category bigint; v_remaining numeric;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
  SELECT * INTO e FROM public.cash_flow_events WHERE id=p_event_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'cash flow event % not found',p_event_id; END IF;
  IF e.event_type<>'debt_payment' OR e.liability_id IS NULL THEN
    RAISE EXCEPTION 'event % is not an installment debt payment',p_event_id;
  END IF;
  SELECT * INTO l FROM public.liabilities WHERE id=e.liability_id;
  IF NOT FOUND OR l.balance_model<>'installment' OR l.payment_account_id IS NULL THEN
    RAISE EXCEPTION 'event % is not linked to an installment liability/payment account',p_event_id;
  END IF;
  IF e.liability_payment_schedule_id IS NOT NULL THEN
    SELECT * INTO s FROM public.liability_payment_schedule WHERE id=e.liability_payment_schedule_id;
  END IF;

  IF e.status='cancelled' THEN RAISE EXCEPTION 'cancelled event cannot be executed'; END IF;
  SELECT greatest(e.amount-coalesce(sum(amount),0),0) INTO v_remaining FROM public.cash_flow_event_funding WHERE cash_flow_event_id=e.id AND relation_type='payment';
  v_amount:=COALESCE(p_actual_amount,v_remaining);
  IF v_amount<=0 OR v_amount>v_remaining+0.005 THEN RAISE EXCEPTION 'payment exceeds remaining amount %',v_remaining; END IF;
  v_principal:=COALESCE(p_principal_amount,s.principal_amount);
  v_interest:=COALESCE(p_interest_amount,s.interest_amount,0);
  v_fee:=COALESCE(p_fee_amount,s.fee_amount,0);
  IF v_principal IS NULL THEN RAISE EXCEPTION 'principal decomposition is unknown for event %',p_event_id; END IF;
  IF round(v_principal+v_interest+v_fee,2)<>round(v_amount,2) THEN
    RAISE EXCEPTION 'decomposition does not equal actual payment amount';
  END IF;

  SELECT public.get_account_balance(l.payment_account_id,p_occurred_at) INTO v_balance;
  IF COALESCE(v_balance,0)<v_amount THEN
    RAISE EXCEPTION 'payment account % has %, but payment requires %',l.payment_account_id,COALESCE(v_balance,0),v_amount;
  END IF;

  SELECT id INTO v_category FROM public.categories
  WHERE category_type='debt' AND is_active
  ORDER BY CASE WHEN name='Погашение долга' THEN 0 ELSE 1 END,id LIMIT 1;

  INSERT INTO public.transactions(
    transaction_date,occurred_at,transaction_type,amount,currency,description,category_id,
    from_account_id,to_account_id,liability_id,budget_effect,notes
  ) VALUES(
    public.finance_business_date(p_occurred_at),p_occurred_at,'debt_payment',v_amount,'RUB',e.description,v_category,
    l.payment_account_id,NULL,l.id,'none','Executed installment payment for cash_flow_event_id='||e.id::text
  ) RETURNING id INTO v_tx_id;

  INSERT INTO public.debt_payment_details(
    transaction_id,liability_id,principal_amount,interest_amount,fee_amount,cash_flow_event_id
  ) VALUES(v_tx_id,l.id,v_principal,v_interest,v_fee,e.id);

  INSERT INTO public.cash_flow_event_funding(
    cash_flow_event_id,transaction_id,amount,relation_type,allocation_source
  ) VALUES(e.id,v_tx_id,v_amount,'payment','auto_installment');

  RETURN v_tx_id;
END
$function$;
