CREATE OR REPLACE FUNCTION public.get_obligations_until_next_income(p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(next_income_date date, event_id bigint, event_date date, description text, amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
with ni as (
  select e.event_date
  from public.cash_flow_events e JOIN public.get_income_event_state_as_of(p_as_of) ist ON ist.event_id=e.id
  where e.event_type='income'
    and ist.derived_status not in ('cancelled','executed')
    and e.event_date >= public.finance_business_date(p_as_of)

  order by e.event_date,e.id
  limit 1
)
select ni.event_date,
       s.event_id,
       s.event_date,
       s.description,
       s.amount,
       s.remaining_payment_amount,
       s.cash_still_required,
       s.derived_status
from ni
join public.get_cash_flow_event_state_as_of(p_as_of) s on true
where s.event_type in ('expense','debt_payment','planned_expense')
  and s.event_date < ni.event_date
  and s.derived_status not in ('cancelled','executed')
order by s.event_date,s.description;
$function$;
