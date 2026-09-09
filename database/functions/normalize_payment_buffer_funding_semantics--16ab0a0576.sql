CREATE OR REPLACE FUNCTION public.normalize_payment_buffer_funding_semantics()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_from_type text;
  v_to_type text;
begin
  if new.from_account_id is null or new.to_account_id is null then
    return new;
  end if;
  select account_type into v_from_type from public.accounts where id=new.from_account_id;
  select account_type into v_to_type from public.accounts where id=new.to_account_id;
  if v_from_type in ('bank','cash') and v_to_type='payment_buffer' and new.transaction_type='debt_payment' then
    new.transaction_type:='transfer';
    new.budget_effect:='none';
  end if;
  return new;
end
$function$;
