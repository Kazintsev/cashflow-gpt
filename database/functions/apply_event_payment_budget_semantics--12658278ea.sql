CREATE OR REPLACE FUNCTION public.apply_event_payment_budget_semantics()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_exempt boolean; v_type text;
BEGIN
 IF NEW.relation_type='payment' THEN
   SELECT living_budget_exempt INTO v_exempt FROM public.cash_flow_events WHERE id=NEW.cash_flow_event_id;
   SELECT transaction_type INTO v_type FROM public.transactions WHERE id=NEW.transaction_id;
   IF v_exempt AND v_type='expense' THEN UPDATE public.transactions SET budget_effect='excluded' WHERE id=NEW.transaction_id; END IF;
 END IF;
 RETURN NEW;
END $function$;
