CREATE OR REPLACE FUNCTION public.get_liability_balance_details(p_liability_id bigint, p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(total_debt numeric, principal_balance numeric, accrued_interest numeric, fees_due numeric, components_known boolean, components_as_of timestamp with time zone)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE l public.liabilities;s public.liability_balance_snapshots;b record;
BEGIN
 SELECT * INTO l FROM public.liabilities WHERE id=p_liability_id;IF NOT FOUND THEN RETURN;END IF;
 SELECT * INTO b FROM public.get_liability_balance(p_liability_id,p_as_of);
 IF l.balance_model='installment' THEN RETURN QUERY SELECT b.total_debt,b.principal_balance,b.accrued_interest,b.fees_due,b.total_debt IS NOT NULL,p_as_of;RETURN;END IF;
 SELECT * INTO s FROM public.liability_balance_snapshots WHERE liability_id=p_liability_id AND balance_as_of<=p_as_of ORDER BY balance_as_of DESC LIMIT 1;
 IF s.balance_as_of=p_as_of AND abs(b.total_debt-(s.principal_balance+s.accrued_interest+s.fees_due))<0.005 THEN
 RETURN QUERY SELECT b.total_debt,s.principal_balance,s.accrued_interest,s.fees_due,true,s.balance_as_of;
 ELSE RETURN QUERY SELECT b.total_debt,NULL::numeric,NULL::numeric,NULL::numeric,false,s.balance_as_of;END IF;
END $function$;
