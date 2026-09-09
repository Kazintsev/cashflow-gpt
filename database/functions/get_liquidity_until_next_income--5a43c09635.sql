CREATE OR REPLACE FUNCTION public.get_liquidity_until_next_income(p_as_of timestamp with time zone DEFAULT now(), p_default_weekly_budget numeric DEFAULT NULL::numeric)
 RETURNS TABLE(as_of timestamp with time zone, business_date date, next_income_date date, next_income_description text, next_income_amount numeric, actual_cash numeric, required_outflows_before_income numeric, remaining_living_budget numeric, future_living_budget numeric, planned_purchase_reserve numeric, free_cash_until_next_income numeric)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_today date := public.finance_business_date(p_as_of);
  v_next_income_date date;
  v_next_income_description text;
  v_next_income_amount numeric;
  v_actual_cash numeric;
  v_outflows numeric := 0;
  v_week_start date;
  v_budget numeric;
  v_spend numeric;
  v_remain numeric;
  v_future_budget numeric := 0;
  v_w date;
  v_horizon_end date;
  v_wb numeric;
  v_purchases numeric := 0; v_credit_reserve numeric:=0;
begin
  select e.event_date,e.description,ist.remaining_amount
    into v_next_income_date,v_next_income_description,v_next_income_amount
  from public.cash_flow_events e JOIN public.get_income_event_state_as_of(p_as_of) ist ON ist.event_id=e.id
  where e.event_type='income'
    and ist.derived_status not in ('cancelled','executed')
    and e.event_date>=v_today

  order by e.event_date,e.id
  limit 1;

  select public.get_actual_cash(p_as_of) into v_actual_cash;

  v_week_start:=date_trunc('week',v_today)::date;
  select coalesce((select lb.amount from public.living_budgets lb where lb.week_start=v_week_start),
                  p_default_weekly_budget,
                  public.finance_setting_numeric('default_weekly_budget',20000))
    into v_budget;

  select coalesce(sum(t.amount),0) into v_spend
  from public.transactions t
  where t.budget_effect='life'
    and t.occurred_at<=p_as_of
    and t.transaction_date between v_week_start and v_today;
  SELECT remaining_reserve INTO v_remain FROM public.get_living_budget_reserve(v_week_start,p_as_of,p_default_weekly_budget);

  if v_next_income_date is not null then
    select coalesce(sum(s.cash_still_required),0) into v_outflows
    from public.get_cash_flow_event_state_as_of(p_as_of) s
    join public.cash_flow_events e on e.id=s.event_id
    where s.event_type in ('expense','debt_payment','planned_expense')
      and s.event_date<v_next_income_date
      and s.derived_status not in ('cancelled','executed')
      and (s.event_type='debt_payment' or e.living_budget_exempt);

    v_horizon_end:=v_next_income_date-1;
    v_w:=v_week_start+7;
    while v_w<=v_horizon_end loop
      select coalesce((select lb.amount from public.living_budgets lb where lb.week_start=v_w),
                      coalesce(p_default_weekly_budget,public.finance_setting_numeric('default_weekly_budget',20000)))
        into v_wb;
      SELECT remaining_reserve INTO v_wb FROM public.get_living_budget_reserve(v_w,p_as_of,p_default_weekly_budget);
      v_future_budget:=v_future_budget+v_wb;
      v_w:=v_w+7;
    end loop;
  else
    v_outflows:=null;
    v_future_budget:=null;
  end if;

  select coalesce(sum(pp.planned_amount),0) into v_purchases
  from public.planned_purchases pp
  where pp.created_at<=p_as_of
    and pp.status<>'cancelled'
    and (pp.closed_at is null or pp.closed_at>p_as_of);

  SELECT coalesce(sum(additional_reserve),0) INTO v_credit_reserve FROM public.get_credit_cash_reserves(p_as_of,v_next_income_date-1);
  return query
  select p_as_of,v_today,v_next_income_date,v_next_income_description,v_next_income_amount,
         v_actual_cash,v_outflows,v_remain,v_future_budget,v_purchases,
         case when v_next_income_date is null then null
              else v_actual_cash-v_outflows-v_remain-v_future_budget-v_purchases-v_credit_reserve end;
end
$function$;
