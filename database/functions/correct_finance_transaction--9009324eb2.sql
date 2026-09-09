CREATE OR REPLACE FUNCTION public.correct_finance_transaction(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb DEFAULT NULL::jsonb, p_debt_details jsonb DEFAULT NULL::jsonb, p_event_allocations jsonb DEFAULT NULL::jsonb, p_receipt_patch jsonb DEFAULT NULL::jsonb)
 RETURNS transactions
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_old public.transactions;v_new public.transactions;x jsonb;k text;v_receipt public.receipts;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
 SELECT * INTO v_old FROM public.transactions WHERE id=p_transaction_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'transaction % not found',p_transaction_id;END IF;
 IF p_patch IS NULL OR jsonb_typeof(p_patch)<>'object' THEN RAISE EXCEPTION 'patch must be a JSON object';END IF;
 FOR k IN SELECT jsonb_object_keys(p_patch) LOOP
  IF k NOT IN ('transaction_date','occurred_at','transaction_type','amount','description','category_id','from_account_id','to_account_id','liability_id','budget_effect','salary_component','salary_period_start','income_event_id','notes','reserve_effect','reserve_cycle','reserve_due_date','reserve_liability_id') THEN RAISE EXCEPTION 'unsupported transaction patch field %',k;END IF;
 END LOOP;
 -- Explicit replacements remove old dependent rows before validating the new ones.
 IF p_event_allocations IS NOT NULL THEN DELETE FROM public.cash_flow_event_funding WHERE transaction_id=p_transaction_id;END IF;
 IF p_debt_details IS NOT NULL THEN DELETE FROM public.debt_payment_details WHERE transaction_id=p_transaction_id;END IF;
 SELECT * INTO v_new FROM jsonb_populate_record(v_old,p_patch);
 UPDATE public.transactions SET transaction_date=v_new.transaction_date,occurred_at=v_new.occurred_at,transaction_type=v_new.transaction_type,amount=v_new.amount,description=v_new.description,category_id=v_new.category_id,from_account_id=v_new.from_account_id,to_account_id=v_new.to_account_id,liability_id=v_new.liability_id,budget_effect=v_new.budget_effect,salary_component=v_new.salary_component,salary_period_start=v_new.salary_period_start,income_event_id=v_new.income_event_id,notes=v_new.notes,reserve_effect=v_new.reserve_effect,reserve_cycle=v_new.reserve_cycle,reserve_due_date=v_new.reserve_due_date,reserve_liability_id=v_new.reserve_liability_id
 WHERE id=p_transaction_id;
 IF p_category_allocations IS NOT NULL THEN
  DELETE FROM public.transaction_category_allocations WHERE transaction_id=p_transaction_id;
  FOR x IN SELECT * FROM jsonb_array_elements(p_category_allocations) LOOP
   INSERT INTO public.transaction_category_allocations(transaction_id,category_id,amount,allocation_source) VALUES(p_transaction_id,(x->>'category_id')::bigint,(x->>'amount')::numeric,'manual');
  END LOOP;
 END IF;
 IF p_event_allocations IS NOT NULL THEN
  DELETE FROM public.cash_flow_event_funding WHERE transaction_id=p_transaction_id;
  FOR x IN SELECT * FROM jsonb_array_elements(p_event_allocations) LOOP
   INSERT INTO public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type,allocation_source) VALUES((x->>'event_id')::bigint,p_transaction_id,(x->>'amount')::numeric,x->>'relation_type','manual');
  END LOOP;
 END IF;
 IF p_debt_details IS NOT NULL AND p_debt_details<>'null'::jsonb THEN
  INSERT INTO public.debt_payment_details(transaction_id,liability_id,principal_amount,interest_amount,fee_amount,cash_flow_event_id)
  VALUES(p_transaction_id,v_new.liability_id,coalesce((p_debt_details->>'principal_amount')::numeric,0),coalesce((p_debt_details->>'interest_amount')::numeric,0),coalesce((p_debt_details->>'fee_amount')::numeric,0),(p_debt_details->>'event_id')::bigint);
 END IF;
 IF p_receipt_patch IS NOT NULL THEN
  FOR k IN SELECT jsonb_object_keys(p_receipt_patch) LOOP
   IF k NOT IN ('total_amount','purchase_at','merchant_name') THEN RAISE EXCEPTION 'unsupported receipt patch field %',k;END IF;
  END LOOP;
  SELECT * INTO v_receipt FROM public.receipts WHERE transaction_id=p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'no receipt linked to transaction %',p_transaction_id;END IF;
  SELECT * INTO v_receipt FROM jsonb_populate_record(v_receipt,p_receipt_patch);
  UPDATE public.receipts SET total_amount=v_receipt.total_amount,purchase_at=v_receipt.purchase_at,merchant_name=v_receipt.merchant_name WHERE transaction_id=p_transaction_id;
 END IF;
 SELECT * INTO v_new FROM public.transactions WHERE id=p_transaction_id;
 RETURN v_new;
END $function$;
