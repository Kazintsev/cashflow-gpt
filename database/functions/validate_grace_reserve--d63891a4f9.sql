CREATE OR REPLACE FUNCTION public.validate_grace_reserve()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE l public.liabilities;v_draw numeric;v_repay numeric;
BEGIN
 IF NEW.reserve_effect='none' THEN RETURN NEW;END IF;
 SELECT * INTO l FROM public.liabilities WHERE id=NEW.reserve_liability_id;
 IF NOT FOUND OR l.balance_model<>'revolving_account' THEN RAISE EXCEPTION 'grace reserve requires a revolving liability';END IF;
 IF NEW.reserve_effect='grace_draw' AND NEW.reserve_due_date<NEW.transaction_date THEN RAISE EXCEPTION 'reserve due date precedes draw';END IF;
 IF NEW.reserve_effect='grace_draw' AND (NEW.transaction_type<>'transfer' OR NEW.from_account_id IS DISTINCT FROM l.linked_account_id OR NEW.to_account_id IS NULL) THEN RAISE EXCEPTION 'grace draw must be a transfer from its credit card';END IF;
 IF NEW.reserve_effect='grace_repay' AND (NEW.transaction_type<>'debt_payment' OR NEW.to_account_id IS DISTINCT FROM l.linked_account_id) THEN RAISE EXCEPTION 'grace repayment must repay its credit card';END IF;
 IF EXISTS(SELECT 1 FROM public.transactions t WHERE t.id<>NEW.id AND t.reserve_liability_id=NEW.reserve_liability_id AND t.reserve_cycle=NEW.reserve_cycle AND t.reserve_due_date<>NEW.reserve_due_date) THEN RAISE EXCEPTION 'all movements of one grace cycle require the same due date';END IF;
 RETURN NEW;
END $function$;
