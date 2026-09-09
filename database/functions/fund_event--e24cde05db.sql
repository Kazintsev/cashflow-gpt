CREATE OR REPLACE FUNCTION public.fund_event(p_event_id bigint, p_from_account_id bigint, p_amount numeric DEFAULT NULL::numeric, p_occurred_at timestamp with time zone DEFAULT now(), p_description text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  e public.cash_flow_events;
  l public.liabilities;
  s record;
  v_from_type text;
  v_to_account_id bigint;
  v_to_type text;
  v_amount numeric;
  v_balance numeric;
  v_tx_id bigint;
  v_before numeric;
  v_after numeric;
  v_next_before date;
  v_next_after date;
begin
 perform pg_advisory_xact_lock(20260905,731);
  select * into e from public.cash_flow_events where id=p_event_id for update;
  if not found then raise exception 'cash flow event % not found',p_event_id; end if;
  if e.status in ('executed','cancelled') then raise exception 'event % is % and cannot be funded',p_event_id,e.status; end if;
  if e.event_type not in ('expense','debt_payment','planned_expense') then raise exception 'event % is not an outflow event',p_event_id; end if;

  select * into s from public.get_cash_flow_event_state_as_of(now()) where event_id=p_event_id;
  v_amount:=coalesce(p_amount,s.cash_still_required);
  if v_amount is null or v_amount<=0 then raise exception 'event % does not require funding',p_event_id; end if;
  if v_amount>s.cash_still_required+0.005 then raise exception 'funding % exceeds cash still required % for event %',v_amount,s.cash_still_required,p_event_id; end if;

  select account_type into v_from_type from public.accounts where id=p_from_account_id and is_active;
  if v_from_type is null or v_from_type not in ('bank','cash') then raise exception 'fund_event source % must be an active bank/cash account',p_from_account_id; end if;

  if e.liability_id is not null then
    select * into l from public.liabilities where id=e.liability_id;
    v_to_account_id:=l.payment_account_id;
  else
    v_to_account_id:=e.account_id;
  end if;
  if v_to_account_id is null then raise exception 'event % has no payment buffer; execute it directly instead of funding',p_event_id; end if;
  select account_type into v_to_type from public.accounts where id=v_to_account_id and is_active;
  if v_to_type is distinct from 'payment_buffer' then raise exception 'event % target account % is %, not payment_buffer',p_event_id,v_to_account_id,v_to_type; end if;

  select public.get_account_balance(p_from_account_id,p_occurred_at) into v_balance;
  if coalesce(v_balance,0)+0.005<v_amount then raise exception 'source account % has %, funding requires %',p_from_account_id,coalesce(v_balance,0),v_amount; end if;

  select free_cash_until_next_income,next_income_date into v_before,v_next_before
  from public.get_liquidity_until_next_income(now(),null);

  insert into public.transactions(transaction_date,occurred_at,transaction_type,amount,currency,description,category_id,from_account_id,to_account_id,liability_id,budget_effect,notes)
  values(public.finance_business_date(p_occurred_at),p_occurred_at,'transfer',v_amount,'RUB',coalesce(p_description,'Обеспечение: '||e.description),null,p_from_account_id,v_to_account_id,null,'none','fund_event cash_flow_event_id='||p_event_id::text)
  returning id into v_tx_id;

  insert into public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type,allocation_source)
  values(p_event_id,v_tx_id,v_amount,'funding','manual');

  select free_cash_until_next_income,next_income_date into v_after,v_next_after
  from public.get_liquidity_until_next_income(now(),null);
  if v_next_before is not null and v_next_before=v_next_after and e.event_date<v_next_before AND (e.event_type='debt_payment' OR e.living_budget_exempt) AND p_occurred_at<=now() then
    perform public.assert_free_cash_invariant(v_before,v_after,'fund_event '||p_event_id::text);
  end if;
  return v_tx_id;
end
$function$;
