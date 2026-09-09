CREATE OR REPLACE FUNCTION public.normalize_credit_card_payment_semantics()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_to_type text;
  v_from_type text;
  v_liability bigint;
  v_debt_category bigint;
BEGIN
  SELECT account_type INTO v_to_type FROM public.accounts WHERE id=NEW.to_account_id;
  SELECT account_type INTO v_from_type FROM public.accounts WHERE id=NEW.from_account_id;

  IF v_to_type='credit_card' AND v_from_type IN ('bank','cash') AND NEW.transaction_type IN ('transfer','debt_payment') THEN
    SELECT id INTO v_liability
    FROM public.liabilities
    WHERE balance_model='revolving_account' AND linked_account_id=NEW.to_account_id AND status='active'
    ORDER BY id LIMIT 1;

    SELECT id INTO v_debt_category
    FROM public.categories
    WHERE category_type='debt' AND is_active
    ORDER BY CASE WHEN name='Погашение долга' THEN 0 ELSE 1 END,id LIMIT 1;

    NEW.transaction_type:='debt_payment';
    NEW.liability_id:=COALESCE(v_liability,NEW.liability_id);
    NEW.category_id:=COALESCE(NEW.category_id,v_debt_category);
    NEW.budget_effect:='none';
  END IF;
  RETURN NEW;
END
$function$;
