CREATE OR REPLACE FUNCTION public.finance_command(p_request_key text, p_command text, p_args jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_id bigint;v_existing jsonb;v_payload jsonb;v_at timestamptz;v_tx public.transactions;d jsonb;a jsonb;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
 IF p_request_key IS NULL OR length(btrim(p_request_key))=0 THEN RAISE EXCEPTION 'request key is required';END IF;
 IF p_args IS NULL OR jsonb_typeof(p_args)<>'object' THEN RAISE EXCEPTION 'args must be a JSON object'; END IF;
 v_payload:=jsonb_build_object('command',p_command,'args',p_args);
 SELECT id,request_payload INTO v_id,v_existing FROM public.transactions WHERE external_ref=p_request_key FOR UPDATE;
 IF FOUND THEN
  IF v_existing IS DISTINCT FROM v_payload THEN RAISE EXCEPTION 'request key % already exists with different arguments',p_request_key;END IF;
  RETURN v_id;
 END IF;
 IF coalesce(p_args->>'reserve_effect','none')<>'none' AND p_command<>'record_transaction' THEN RAISE EXCEPTION 'tagged grace movements require record_transaction with optional event_allocations';END IF;
 v_at:=coalesce((p_args->>'occurred_at')::timestamptz,CASE WHEN p_args ? 'transaction_date' THEN public.finance_day_start((p_args->>'transaction_date')::date)+interval '12 hours' ELSE now() END);
 IF p_command='fund_event' THEN
  v_id:=public.fund_event((p_args->>'event_id')::bigint,(p_args->>'from_account_id')::bigint,(p_args->>'amount')::numeric,v_at,p_args->>'description');
 ELSIF p_command='execute_event' THEN
  v_id:=public.execute_event((p_args->>'event_id')::bigint,(p_args->>'from_account_id')::bigint,v_at,(p_args->>'amount')::numeric,(p_args->>'principal_amount')::numeric,(p_args->>'interest_amount')::numeric,(p_args->>'fee_amount')::numeric);
 ELSIF p_command='record_transaction' THEN
  INSERT INTO public.transactions(transaction_date,occurred_at,transaction_type,amount,currency,description,category_id,from_account_id,to_account_id,liability_id,budget_effect,salary_component,salary_period_start,income_event_id,notes,external_ref,request_payload)
  VALUES(coalesce((p_args->>'transaction_date')::date,public.finance_business_date(v_at)),v_at,p_args->>'transaction_type',(p_args->>'amount')::numeric,coalesce(p_args->>'currency','RUB'),p_args->>'description',(p_args->>'category_id')::bigint,(p_args->>'from_account_id')::bigint,(p_args->>'to_account_id')::bigint,(p_args->>'liability_id')::bigint,p_args->>'budget_effect',p_args->>'salary_component',(p_args->>'salary_period_start')::date,(p_args->>'income_event_id')::bigint,p_args->>'notes',p_request_key,v_payload)
  RETURNING id INTO v_id;
 ELSE RAISE EXCEPTION 'unsupported finance command %',p_command; END IF;
 IF p_args ? 'event_allocations' THEN
  IF p_command<>'record_transaction' THEN RAISE EXCEPTION 'event_allocations require record_transaction';END IF;
  FOR a IN SELECT * FROM jsonb_array_elements(p_args->'event_allocations') LOOP
   INSERT INTO public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type,allocation_source) VALUES((a->>'event_id')::bigint,v_id,(a->>'amount')::numeric,a->>'relation_type','manual');
  END LOOP;
 END IF;
 IF p_args ? 'category_allocations' THEN
  FOR a IN SELECT * FROM jsonb_array_elements(p_args->'category_allocations') LOOP
   INSERT INTO public.transaction_category_allocations(transaction_id,category_id,amount,allocation_source)
   VALUES(v_id,(a->>'category_id')::bigint,(a->>'amount')::numeric,'manual');
  END LOOP;
 END IF;
 IF p_args ? 'debt_details' THEN
  IF p_command<>'record_transaction' THEN RAISE EXCEPTION 'debt_details are accepted only for record_transaction';END IF;
  d:=p_args->'debt_details';
  INSERT INTO public.debt_payment_details(transaction_id,liability_id,principal_amount,interest_amount,fee_amount,cash_flow_event_id)
  VALUES(v_id,(p_args->>'liability_id')::bigint,coalesce((d->>'principal_amount')::numeric,0),coalesce((d->>'interest_amount')::numeric,0),coalesce((d->>'fee_amount')::numeric,0),(d->>'event_id')::bigint);
 END IF;
 UPDATE public.transactions SET external_ref=p_request_key,request_payload=v_payload,reserve_effect=coalesce(p_args->>'reserve_effect','none'),reserve_cycle=p_args->>'reserve_cycle',reserve_due_date=(p_args->>'reserve_due_date')::date,reserve_liability_id=(p_args->>'reserve_liability_id')::bigint WHERE id=v_id;
 RETURN v_id;
END $function$;
