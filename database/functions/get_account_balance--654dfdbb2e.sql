CREATE OR REPLACE FUNCTION public.get_account_balance(p_account_id bigint, p_as_of timestamp with time zone DEFAULT now())
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_base numeric; v_anchor timestamptz; v_open_date date;
BEGIN
 SELECT s.balance,s.balance_as_of INTO v_base,v_anchor FROM public.account_balance_snapshots s WHERE s.account_id=p_account_id AND s.balance_as_of<=p_as_of ORDER BY s.balance_as_of DESC LIMIT 1;
 IF v_base IS NULL THEN SELECT a.opening_balance,a.opening_balance_date INTO v_base,v_open_date FROM public.accounts a WHERE a.id=p_account_id; IF NOT FOUND THEN RETURN NULL; END IF; v_base:=COALESCE(v_base,0); v_anchor:=CASE WHEN v_open_date IS NOT NULL THEN public.finance_day_start(v_open_date)-interval '1 microsecond' ELSE '-infinity'::timestamptz END; END IF;
 RETURN v_base+COALESCE((SELECT SUM(CASE WHEN t.from_account_id=p_account_id THEN -t.amount WHEN t.to_account_id=p_account_id THEN t.amount ELSE 0 END) FROM public.transactions t WHERE (t.from_account_id=p_account_id OR t.to_account_id=p_account_id) AND t.occurred_at>v_anchor AND t.occurred_at<=p_as_of),0);
END $function$;
