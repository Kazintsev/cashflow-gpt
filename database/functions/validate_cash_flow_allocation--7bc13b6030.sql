CREATE OR REPLACE FUNCTION public.validate_cash_flow_allocation()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_tx_amount numeric;
  v_tx_used numeric;
  v_event_amount numeric;
  v_event_used numeric;
  v_cash_used numeric;
  v_tx_type text;
  v_from_id bigint;
  v_to_id bigint;
  v_from_type text;
  v_to_type text;
  v_event_type text;
  v_liability_id bigint;
  v_event_account_id bigint;
  v_balance_model text;
  v_payment_account_id bigint;
  v_linked_account_id bigint;
begin
  select t.amount,t.transaction_type,t.from_account_id,t.to_account_id,fa.account_type,ta.account_type
    into v_tx_amount,v_tx_type,v_from_id,v_to_id,v_from_type,v_to_type
  from public.transactions t
  left join public.accounts fa on fa.id=t.from_account_id
  left join public.accounts ta on ta.id=t.to_account_id
  where t.id=new.transaction_id;
  if v_tx_amount is null then raise exception 'transaction % not found',new.transaction_id; end if;

  select e.amount,e.event_type,e.liability_id,e.account_id
    into v_event_amount,v_event_type,v_liability_id,v_event_account_id
  from public.cash_flow_events e where e.id=new.cash_flow_event_id;
  if v_event_amount is null then raise exception 'cash flow event % not found',new.cash_flow_event_id; end if;

  if v_liability_id is not null then
    select l.balance_model,l.payment_account_id,l.linked_account_id
      into v_balance_model,v_payment_account_id,v_linked_account_id
    from public.liabilities l where l.id=v_liability_id;
  end if;

  select coalesce(sum(f.amount),0) into v_tx_used
  from public.cash_flow_event_funding f
  where f.transaction_id=new.transaction_id and f.id<>coalesce(new.id,-1);
  if v_tx_used+new.amount>v_tx_amount+0.005 then
    raise exception 'allocation exceeds transaction amount: used %, new %, transaction %',v_tx_used,new.amount,v_tx_amount;
  end if;

  select coalesce(sum(f.amount),0) into v_event_used
  from public.cash_flow_event_funding f
  where f.cash_flow_event_id=new.cash_flow_event_id
    and f.relation_type=new.relation_type
    and f.id<>coalesce(new.id,-1);
  if v_event_used+new.amount>v_event_amount+0.005 then
    raise exception '% allocation exceeds event amount: used %, new %, event %',new.relation_type,v_event_used,new.amount,v_event_amount;
  end if;

  if new.relation_type='funding' then
    if v_tx_type<>'transfer' or v_from_type not in ('bank','cash') or v_to_type<>'payment_buffer' then
      raise exception 'funding must be a transfer from bank/cash to a payment_buffer; transaction % is type %, from %, to %',new.transaction_id,v_tx_type,v_from_type,v_to_type;
    end if;
    if v_balance_model='installment' and v_payment_account_id is not null and v_to_id<>v_payment_account_id then
      raise exception 'funding for installment liability % must go to payment account %, got %',v_liability_id,v_payment_account_id,v_to_id;
    end if;
    if v_liability_id is null and v_event_account_id is not null and v_to_id<>v_event_account_id then
      raise exception 'funding for event % must go to event payment account %, got %',new.cash_flow_event_id,v_event_account_id,v_to_id;
    end if;
  elsif new.relation_type='payment' then
    if v_event_type='debt_payment' then
      if v_balance_model='installment' then
        if v_payment_account_id is null or v_from_id<>v_payment_account_id or v_to_id is not null or v_tx_type<>'debt_payment' then
          raise exception 'installment payment must be an actual debit from payment_buffer % to external payee; transaction % is type %, from %, to %',v_payment_account_id,new.transaction_id,v_tx_type,v_from_id,v_to_id;
        end if;
      elsif v_balance_model='revolving_account' then
        if v_tx_type<>'debt_payment' or v_from_type not in ('bank','cash') or v_to_id is distinct from v_linked_account_id then
          raise exception 'revolving payment must be debt_payment from bank/cash to linked account %',v_linked_account_id;
        end if;
      else
        raise exception 'unsupported liability model % for payment allocation',v_balance_model;
      end if;
    elsif v_event_type in ('expense','planned_expense') then
      if v_tx_type<>'expense' or v_from_type not in ('bank','cash','payment_buffer') or v_to_id is not null then
        raise exception 'expense payment must be an actual expense debit to external payee';
      end if;
    else
      raise exception 'payment allocations are not supported for event_type %',v_event_type;
    end if;
  end if;

  if v_from_type in ('bank','cash') then
    select coalesce(sum(f.amount),0) into v_cash_used
    from public.cash_flow_event_funding f
    join public.transactions t on t.id=f.transaction_id
    join public.accounts a on a.id=t.from_account_id
    where f.cash_flow_event_id=new.cash_flow_event_id
      and f.id<>coalesce(new.id,-1)
      and a.account_type in ('bank','cash');
    if v_cash_used+new.amount>v_event_amount+0.005 then
      raise exception 'cash committed to event exceeds event amount: committed %, new %, event %',v_cash_used,new.amount,v_event_amount;
    end if;
  end if;
  return new;
end
$function$;
