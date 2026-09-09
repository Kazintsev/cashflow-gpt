CREATE OR REPLACE FUNCTION public.execute_event(p_event_id bigint, p_from_account_id bigint DEFAULT NULL::bigint, p_occurred_at timestamp with time zone DEFAULT now(), p_actual_amount numeric DEFAULT NULL::numeric, p_principal_amount numeric DEFAULT NULL::numeric, p_interest_amount numeric DEFAULT NULL::numeric, p_fee_amount numeric DEFAULT NULL::numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  e public.cash_flow_events;
  l public.liabilities;
  sch public.liability_payment_schedule;
  s record;
  v_amount numeric;
  v_from_id bigint;
  v_from_type text;
  v_tx_id bigint;
  v_category bigint;
  v_principal numeric;
  v_interest numeric;
  v_fee numeric;
  v_before numeric;
  v_after numeric;
  v_next_before date;
  v_next_after date; v_already numeric; v_available numeric;
begin
 perform pg_advisory_xact_lock(20260905,731);
  select * into e from public.cash_flow_events where id=p_event_id for update;
  if not found then raise exception 'cash flow event % not found',p_event_id; end if;
  if e.status='cancelled' then raise exception 'event % is % and cannot be executed again',p_event_id,e.status; end if;
  if e.event_type not in ('expense','debt_payment','planned_expense') then raise exception 'event % is not an executable outflow event',p_event_id; end if;

  select * into s from public.get_cash_flow_event_state_as_of(now()) where event_id=p_event_id;
  SELECT greatest(e.amount-coalesce(sum(amount),0),0) INTO v_available FROM public.cash_flow_event_funding WHERE cash_flow_event_id=e.id AND relation_type='payment';
  v_amount:=coalesce(p_actual_amount,v_available);
  if v_amount is null or v_amount<=0 then raise exception 'event % has no remaining payment',p_event_id; end if;
  if v_amount>v_available+0.005 then raise exception 'payment % exceeds remaining % for event %',v_amount,s.remaining_payment_amount,p_event_id; end if;

  select free_cash_until_next_income,next_income_date into v_before,v_next_before
  from public.get_liquidity_until_next_income(now(),null);

  if e.event_type='debt_payment' then
    if e.liability_id is null then raise exception 'debt payment event % has no liability',p_event_id; end if;
    select * into l from public.liabilities where id=e.liability_id;
    if l.balance_model='installment' then
      v_from_id:=coalesce(p_from_account_id,l.payment_account_id);
      if v_from_id is distinct from l.payment_account_id then
        raise exception 'installment event % must be debited from payment buffer %',p_event_id,l.payment_account_id;
      end if;
      if e.liability_payment_schedule_id is not null then
        select * into sch from public.liability_payment_schedule where id=e.liability_payment_schedule_id;
      end if;
      if p_principal_amount is null and p_interest_amount is null and p_fee_amount is null then
        if v_amount<>e.amount and e.liability_payment_schedule_id is not null then
          raise exception 'partial installment payment requires explicit principal/interest/fee decomposition';
        end if;
        if e.liability_payment_schedule_id is not null and sch.principal_amount is not null then
          v_principal:=sch.principal_amount; v_interest:=coalesce(sch.interest_amount,0); v_fee:=coalesce(sch.fee_amount,0);
        elsif l.annual_rate=0 then
          v_principal:=v_amount; v_interest:=0; v_fee:=0;
        else
          raise exception 'principal/interest decomposition is unknown for event %; provide it explicitly',p_event_id;
        end if;
      else
        v_principal:=coalesce(p_principal_amount,0);
        v_interest:=coalesce(p_interest_amount,0);
        v_fee:=coalesce(p_fee_amount,0);
      end if;
      if round(v_principal+v_interest+v_fee,2)<>round(v_amount,2) then
        raise exception 'principal + interest + fee must equal actual payment amount';
      end if;
      v_tx_id:=public.execute_installment_payment(p_event_id,p_occurred_at,v_amount,v_principal,v_interest,v_fee);
    elsif l.balance_model='revolving_account' then
      v_from_id:=p_from_account_id;
      if v_from_id is null then raise exception 'revolving payment requires p_from_account_id'; end if;
      select account_type into v_from_type from public.accounts where id=v_from_id and is_active;
      if v_from_type is null or v_from_type not in ('bank','cash') then raise exception 'revolving payment source must be bank/cash'; end if;
      select id into v_category from public.categories where category_type='debt' and is_active order by case when name='Погашение долга' then 0 else 1 end,id limit 1;
      insert into public.transactions(transaction_date,occurred_at,transaction_type,amount,currency,description,category_id,from_account_id,to_account_id,liability_id,budget_effect,notes)
      values(public.finance_business_date(p_occurred_at),p_occurred_at,'debt_payment',v_amount,'RUB',e.description,v_category,v_from_id,l.linked_account_id,l.id,'none','execute_event cash_flow_event_id='||p_event_id::text)
      returning id into v_tx_id;
      select coalesce(sum(amount),0) into v_already from public.cash_flow_event_funding where transaction_id=v_tx_id and cash_flow_event_id=p_event_id and relation_type='payment';
      if v_already<v_amount then
        insert into public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type,allocation_source)
        values(p_event_id,v_tx_id,v_amount-v_already,'payment','manual')
        on conflict(cash_flow_event_id,transaction_id) do update set amount=public.cash_flow_event_funding.amount+excluded.amount;
      end if;
    else
      raise exception 'unsupported liability model %',l.balance_model;
    end if;
  else
    v_from_id:=coalesce(p_from_account_id,e.account_id);
    if v_from_id is null then raise exception 'expense event % requires p_from_account_id',p_event_id; end if;
    select account_type into v_from_type from public.accounts where id=v_from_id and is_active;
    if v_from_type is null or v_from_type not in ('bank','cash','payment_buffer') then raise exception 'expense source account % has unsupported type %',v_from_id,v_from_type; end if;
    insert into public.transactions(transaction_date,occurred_at,transaction_type,amount,currency,description,category_id,from_account_id,to_account_id,liability_id,budget_effect,notes)
    values(public.finance_business_date(p_occurred_at),p_occurred_at,'expense',v_amount,'RUB',e.description,null,v_from_id,null,e.liability_id,case when e.living_budget_exempt then 'excluded' else 'life' end,'execute_event cash_flow_event_id='||p_event_id::text)
    returning id into v_tx_id;
    insert into public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type,allocation_source)
    values(p_event_id,v_tx_id,v_amount,'payment','manual');
  end if;

  select free_cash_until_next_income,next_income_date into v_after,v_next_after
  from public.get_liquidity_until_next_income(now(),null);
  if v_next_before is not null and v_next_before=v_next_after and e.event_date<v_next_before AND (e.event_type='debt_payment' OR e.living_budget_exempt) AND p_occurred_at<=now() then
    perform public.assert_free_cash_invariant(v_before,v_after,'execute_event '||p_event_id::text);
  end if;
  return v_tx_id;
end
$function$;
