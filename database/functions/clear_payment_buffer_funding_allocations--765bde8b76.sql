CREATE OR REPLACE FUNCTION public.clear_payment_buffer_funding_allocations()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  delete from public.cash_flow_event_funding
  where transaction_id=old.id
    and allocation_source='auto_payment_buffer';

  if tg_op='DELETE' then
    return old;
  end if;
  return new;
end
$function$;
