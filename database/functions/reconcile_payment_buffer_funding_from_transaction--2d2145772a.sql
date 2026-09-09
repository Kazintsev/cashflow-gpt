CREATE OR REPLACE FUNCTION public.reconcile_payment_buffer_funding_from_transaction()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_payment_account_id bigint;
  v_from_type text;
  v_available numeric;
  v_alloc numeric;
  r record;
begin
  if new.liability_id is null or new.to_account_id is null or new.from_account_id is null then
    return new;
  end if;

  select l.payment_account_id
  into v_payment_account_id
  from public.liabilities l
  where l.id=new.liability_id;

  select a.account_type
  into v_from_type
  from public.accounts a
  where a.id=new.from_account_id;

  if v_payment_account_id is distinct from new.to_account_id
     or v_from_type not in ('bank','cash')
     or new.transaction_type<>'transfer' or NOT EXISTS(SELECT 1 FROM public.accounts a WHERE a.id=NEW.to_account_id AND a.account_type='payment_buffer') then
    return new;
  end if;

  delete from public.cash_flow_event_funding
  where transaction_id=new.id
    and allocation_source='auto_payment_buffer';

  select greatest(new.amount-coalesce(sum(f.amount),0),0)
  into v_available
  from public.cash_flow_event_funding f
  where f.transaction_id=new.id;

  if coalesce(v_available,0)<=0 then
    return new;
  end if;

  for r in
    select s.event_id,s.cash_still_required,e.event_date
    from public.cash_flow_event_state s
    join public.cash_flow_events e on e.id=s.event_id
    where e.liability_id=new.liability_id
      and e.event_type='debt_payment'
      and e.status<>'cancelled'
      and s.cash_still_required>0
    order by
      case when e.event_date<=new.transaction_date then 0 else 1 end,
      abs(e.event_date-new.transaction_date),
      e.event_date,
      e.id
  loop
    exit when v_available<=0;
    v_alloc:=least(v_available,r.cash_still_required);
    if v_alloc>0 then
      insert into public.cash_flow_event_funding(
        cash_flow_event_id,transaction_id,amount,relation_type,allocation_source
      ) values(
        r.event_id,new.id,v_alloc,'funding','auto_payment_buffer'
      );
      v_available:=v_available-v_alloc;
    end if;
  end loop;

  return new;
end
$function$;
