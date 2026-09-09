CREATE OR REPLACE FUNCTION public.get_liability_balance(p_liability_id bigint, p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_model text; v_account bigint; v_p numeric:=0; v_i numeric:=0; v_f numeric:=0; v_anchor timestamptz;
BEGIN
 SELECT balance_model,linked_account_id INTO v_model,v_account FROM public.liabilities WHERE id=p_liability_id; IF NOT FOUND THEN RETURN; END IF;
 IF v_model='revolving_account' THEN v_p:=GREATEST(-COALESCE(public.get_account_balance(v_account,p_as_of),0),0); RETURN QUERY SELECT v_p,0::numeric,0::numeric,v_p; RETURN; END IF;
 SELECT s.principal_balance,s.accrued_interest,s.fees_due,s.balance_as_of INTO v_p,v_i,v_f,v_anchor FROM public.liability_balance_snapshots s WHERE s.liability_id=p_liability_id AND s.balance_as_of<=p_as_of ORDER BY s.balance_as_of DESC LIMIT 1;
 IF v_anchor IS NULL THEN RETURN QUERY SELECT NULL::numeric,NULL::numeric,NULL::numeric,NULL::numeric; RETURN; END IF;
 SELECT v_p+COALESCE(SUM(CASE m.movement_type WHEN 'principal_increase' THEN m.amount WHEN 'principal_payment' THEN -m.amount WHEN 'principal_adjustment' THEN m.direction*m.amount ELSE 0 END),0),v_i+COALESCE(SUM(CASE m.movement_type WHEN 'interest_accrual' THEN m.amount WHEN 'interest_payment' THEN -m.amount WHEN 'interest_adjustment' THEN m.direction*m.amount ELSE 0 END),0),v_f+COALESCE(SUM(CASE m.movement_type WHEN 'fee_accrual' THEN m.amount WHEN 'fee_payment' THEN -m.amount WHEN 'fee_adjustment' THEN m.direction*m.amount ELSE 0 END),0) INTO v_p,v_i,v_f FROM public.liability_movements m WHERE m.liability_id=p_liability_id AND m.effective_at>v_anchor AND m.effective_at<=p_as_of;
 v_p:=GREATEST(v_p,0);v_i:=GREATEST(v_i,0);v_f:=GREATEST(v_f,0); RETURN QUERY SELECT v_p,v_i,v_f,v_p+v_i+v_f;
END $function$;
