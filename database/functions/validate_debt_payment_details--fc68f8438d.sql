CREATE OR REPLACE FUNCTION public.validate_debt_payment_details()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_amount numeric;
  v_type text;
  v_liability bigint;
BEGIN
  SELECT amount,transaction_type,liability_id
  INTO v_amount,v_type,v_liability
  FROM public.transactions
  WHERE id=NEW.transaction_id;

  IF v_amount IS NULL THEN
    RAISE EXCEPTION 'transaction % not found',NEW.transaction_id;
  END IF;
  IF v_type <> 'debt_payment' THEN
    RAISE EXCEPTION 'transaction % must be debt_payment to have debt_payment_details',NEW.transaction_id;
  END IF;
  IF v_liability IS NOT NULL AND v_liability <> NEW.liability_id THEN
    RAISE EXCEPTION 'transaction liability % does not match detail liability %',v_liability,NEW.liability_id;
  END IF;
  IF round(NEW.principal_amount + NEW.interest_amount + NEW.fee_amount,2) <> round(v_amount,2) THEN
    RAISE EXCEPTION 'debt payment decomposition % does not equal transaction amount %',
      NEW.principal_amount + NEW.interest_amount + NEW.fee_amount,v_amount;
  END IF;
  RETURN NEW;
END
$function$;
