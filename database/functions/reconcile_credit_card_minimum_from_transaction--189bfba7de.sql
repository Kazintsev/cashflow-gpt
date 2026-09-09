CREATE OR REPLACE FUNCTION public.reconcile_credit_card_minimum_from_transaction()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT e.id
    FROM public.cash_flow_events e
    JOIN public.liabilities l ON l.id=e.liability_id
    WHERE e.fulfillment_mode='cumulative_contributions'
      AND e.status<>'cancelled'
      AND l.balance_model='revolving_account'
      AND l.linked_account_id=NEW.to_account_id
      AND NEW.transaction_date BETWEEN e.period_start AND e.period_end
  LOOP
    PERFORM public.reconcile_credit_card_minimum(r.id);
  END LOOP;
  RETURN NEW;
END
$function$;
