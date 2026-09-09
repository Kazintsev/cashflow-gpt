CREATE OR REPLACE FUNCTION public.get_settlement_attention(p_as_of date DEFAULT finance_business_date(now()))
 RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, paid_amount numeric, funded_amount numeric, cash_still_required numeric, remaining_payment_amount numeric, derived_status text, timing_status text, attention_status text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select
    s.event_id,
    s.event_date,
    s.description,
    s.amount,
    s.paid_amount,
    s.funded_amount,
    s.cash_still_required,
    s.remaining_payment_amount,
    s.derived_status,
    case
      when s.event_date < p_as_of and s.derived_status not in ('executed','cancelled') then 'overdue_unconfirmed'
      when s.event_date = p_as_of then 'due_today'
      else 'other'
    end as timing_status,
    case
      when s.derived_status='executed' then 'исполнено'
      when s.paid_amount>0 and s.remaining_payment_amount>0 and s.cash_still_required=0 then 'частично списано, остаток обеспечен'
      when s.paid_amount>0 and s.remaining_payment_amount>0 then 'частично списано, требуется доплата/обеспечение'
      when s.cash_still_required=0 and s.remaining_payment_amount>0 then 'обеспечено, списание не подтверждено'
      when s.cash_still_required>0 then 'не обеспечено'
      else s.derived_status
    end as attention_status
  from public.get_cash_flow_event_state_as_of(public.finance_day_end(p_as_of)) s
  where s.event_type in ('expense','debt_payment','planned_expense')
    and s.derived_status <> 'cancelled'
    and (
      s.event_date = p_as_of
      or (s.event_date < p_as_of and s.derived_status <> 'executed')
    )
  order by s.event_date,s.description;
$function$;
