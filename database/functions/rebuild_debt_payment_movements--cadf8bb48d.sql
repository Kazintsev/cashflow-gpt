CREATE OR REPLACE FUNCTION public.rebuild_debt_payment_movements(p_liability_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;b record;v_i numeric;v_f numeric;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
 DELETE FROM public.liability_movements WHERE liability_id=p_liability_id AND debt_payment_detail_id IS NOT NULL;
 FOR r IN SELECT d.*,t.occurred_at FROM public.debt_payment_details d JOIN public.transactions t ON t.id=d.transaction_id WHERE d.liability_id=p_liability_id ORDER BY t.occurred_at,t.id LOOP
  SELECT * INTO b FROM public.get_liability_balance(p_liability_id,r.occurred_at);
  IF b.total_debt IS NULL THEN RAISE EXCEPTION 'initial liability snapshot required for % before %',p_liability_id,r.occurred_at; END IF;
  v_i:=greatest(r.interest_amount-coalesce(b.accrued_interest,0),0);v_f:=greatest(r.fee_amount-coalesce(b.fees_due,0),0);
  INSERT INTO public.liability_movements(liability_id,effective_at,movement_type,amount,transaction_id,cash_flow_event_id,debt_payment_detail_id,notes)
  SELECT r.liability_id,r.occurred_at,x.kind,x.amount,r.transaction_id,r.cash_flow_event_id,r.id,'Derived from debt payment detail'
  FROM (VALUES ('interest_accrual',v_i),('fee_accrual',v_f),('principal_payment',r.principal_amount),('interest_payment',r.interest_amount),('fee_payment',r.fee_amount)) x(kind,amount) WHERE x.amount>0;
 END LOOP;
 PERFORM public.sync_liability_principal_cache(p_liability_id);
END $function$;
