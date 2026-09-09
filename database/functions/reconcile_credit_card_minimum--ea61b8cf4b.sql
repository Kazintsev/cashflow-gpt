CREATE OR REPLACE FUNCTION public.reconcile_credit_card_minimum(p_event_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  e public.cash_flow_events;
  l public.liabilities;
  r record;
  v_remaining numeric;
  v_tx_used numeric;
  v_available numeric;
  v_alloc numeric;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
  SELECT * INTO e FROM public.cash_flow_events WHERE id=p_event_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'cash flow event % not found',p_event_id; END IF;
  IF e.fulfillment_mode <> 'cumulative_contributions' OR e.liability_id IS NULL THEN RETURN; END IF;

  SELECT * INTO l FROM public.liabilities WHERE id=e.liability_id;
  IF NOT FOUND OR l.balance_model <> 'revolving_account' OR l.linked_account_id IS NULL THEN RETURN; END IF;

  DELETE FROM public.cash_flow_event_funding
  WHERE cash_flow_event_id=e.id AND allocation_source='auto_card_minimum';

  SELECT greatest(e.amount-coalesce(sum(amount),0),0) INTO v_remaining FROM public.cash_flow_event_funding WHERE cash_flow_event_id=e.id;
  FOR r IN
    SELECT t.*
    FROM public.transactions t
    JOIN public.accounts fa ON fa.id=t.from_account_id
    WHERE t.to_account_id=l.linked_account_id
      AND fa.account_type IN ('bank','cash')
      AND t.transaction_type IN ('transfer','debt_payment')
      AND t.transaction_date BETWEEN e.period_start AND e.period_end
    ORDER BY t.occurred_at,t.id
  LOOP
    EXIT WHEN v_remaining<=0;
    SELECT COALESCE(SUM(f.amount),0) INTO v_tx_used
    FROM public.cash_flow_event_funding f WHERE f.transaction_id=r.id;
    v_available:=GREATEST(r.amount-v_tx_used,0);
    v_alloc:=LEAST(v_available,v_remaining);
    IF v_alloc>0 THEN
      INSERT INTO public.cash_flow_event_funding(
        cash_flow_event_id,transaction_id,amount,relation_type,allocation_source
      ) VALUES(e.id,r.id,v_alloc,'payment','auto_card_minimum');
      v_remaining:=v_remaining-v_alloc;
    END IF;
  END LOOP;

  PERFORM public.refresh_cash_flow_event_status(e.id);
END
$function$;
