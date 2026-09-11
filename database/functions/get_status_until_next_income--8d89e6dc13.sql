CREATE OR REPLACE FUNCTION public.get_status_until_next_income(p_as_of timestamp with time zone DEFAULT now(), p_default_weekly_budget numeric DEFAULT NULL::numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  l record;
  v_today date:=public.finance_business_date(p_as_of);
  v_cash jsonb;
  v_previous_day_operations jsonb;
  v_today_events jsonb;
  v_controls jsonb;
  v_future jsonb;
  v_integrity jsonb;
  v_integrity_errors integer;
  v_week_start date;
  v_week_budget numeric;
  v_week_spend numeric;
  v_week_remaining numeric;
  v_week_overrun numeric;
begin
  select * into l from public.get_liquidity_until_next_income(p_as_of,p_default_weekly_budget);

  v_week_start:=date_trunc('week',v_today)::date;
  select coalesce((select lb.amount from public.living_budgets lb where lb.week_start=v_week_start),
                  p_default_weekly_budget,
                  public.finance_setting_numeric('default_weekly_budget',20000))
    into v_week_budget;
  select coalesce(sum(t.amount),0) into v_week_spend
  from public.transactions t
  where t.budget_effect='life' and t.occurred_at<=p_as_of and t.transaction_date between v_week_start and v_today;
  v_week_remaining:=greatest(v_week_budget-v_week_spend,0);
  v_week_overrun:=greatest(v_week_spend-v_week_budget,0);

  select coalesce(jsonb_agg(jsonb_build_object(
           'account_id',x.id,'name',x.name,
           'short_name',case when x.account_type='cash' then 'нал' else x.name end,
           'account_type',x.account_type,'balance',x.balance
         ) order by case when x.account_type='cash' then 0 when x.account_type='bank' then 1 else 2 end,x.id),'[]'::jsonb)
    into v_cash
  from (
    select a.id,a.name,a.account_type,public.get_account_balance(a.id,p_as_of) balance
    from public.accounts a where a.is_active and a.account_type in ('bank','cash')
  ) x;

  with st as (select * from public.get_cash_flow_event_state_as_of(p_as_of))
  select coalesce(jsonb_agg(jsonb_build_object(
           'event_id',s.event_id,'date',s.event_date,'description',s.description,
           'amount',s.remaining_payment_amount,'cash_still_required',s.cash_still_required,
           'derived_status',s.derived_status,'living_budget_exempt',e.living_budget_exempt,
           'coverage',case when s.cash_still_required=0 then 'funded'
                           when s.event_type in ('expense','planned_expense') and not e.living_budget_exempt then 'living_budget'
                           else 'unsecured' end,
           'counts_against_free_cash',case when s.event_type='debt_payment' or e.living_budget_exempt then true else false end
         ) order by s.description),'[]'::jsonb)
    into v_today_events
  from st s join public.cash_flow_events e on e.id=s.event_id
  where s.event_date=v_today and s.event_type in ('expense','debt_payment','planned_expense')
    and s.derived_status not in ('executed','cancelled');

  with st as (select * from public.get_cash_flow_event_state_as_of(p_as_of))
  select coalesce(jsonb_agg(jsonb_build_object(
           'event_id',s.event_id,'date',s.event_date,'description',s.description,
           'amount',s.remaining_payment_amount,'cash_still_required',s.cash_still_required,
           'derived_status',s.derived_status,
           'attention',case when s.cash_still_required>0 then 'requires_action' else 'secured_unconfirmed' end
         ) order by s.event_date,s.description),'[]'::jsonb)
    into v_controls
  from st s
  where s.event_date<v_today and s.event_type in ('expense','debt_payment','planned_expense')
    and s.derived_status not in ('executed','cancelled');

  with st as (select * from public.get_cash_flow_event_state_as_of(p_as_of))
  select coalesce(jsonb_agg(jsonb_build_object(
           'event_id',s.event_id,'date',s.event_date,'description',s.description,
           'amount',s.remaining_payment_amount,'cash_still_required',s.cash_still_required,
           'derived_status',s.derived_status,'living_budget_exempt',e.living_budget_exempt,
           'coverage',case when s.cash_still_required=0 then 'funded'
                           when s.event_type in ('expense','planned_expense') and not e.living_budget_exempt then 'living_budget'
                           else 'unsecured' end,
           'counts_against_free_cash',case when s.event_type='debt_payment' or e.living_budget_exempt then true else false end
         ) order by s.event_date,s.description),'[]'::jsonb)
    into v_future
  from st s join public.cash_flow_events e on e.id=s.event_id
  where l.next_income_date is not null and s.event_date>v_today and s.event_date<l.next_income_date
    and s.event_type in ('expense','debt_payment','planned_expense') and s.derived_status not in ('executed','cancelled');

  select coalesce(jsonb_agg(jsonb_build_object('severity',q.severity,'code',q.code,'entity_type',q.entity_type,'entity_id',q.entity_id,'message',q.message,'details',q.details)),'[]'::jsonb),
         count(*) filter(where q.severity='error')
    into v_integrity,v_integrity_errors
  from public.finance_integrity_check(p_as_of) q;

  -- Reconciliation list: a complete business day, not a rolling 24 hours.
  select jsonb_build_object(
    'date',v_today-1,
    'timezone',public.finance_setting_text('business_timezone','Europe/Moscow'),
    'start_at',public.finance_day_start(v_today-1),
    'end_at_exclusive',public.finance_day_start(v_today),
    'count',count(*),
    'operations',coalesce(jsonb_agg(jsonb_build_object(
      'transaction_id',t.id,'occurred_at',t.occurred_at,
      'local_time',to_char(t.occurred_at AT TIME ZONE public.finance_setting_text('business_timezone','Europe/Moscow'),'HH24:MI:SS'),
      'transaction_type',t.transaction_type,'amount',t.amount,'currency',t.currency,
      'description',t.description,'budget_effect',t.budget_effect,
      'from_account_id',t.from_account_id,'from_account_name',fa.name,
      'to_account_id',t.to_account_id,'to_account_name',ta.name,
      'liability_id',t.liability_id
    ) order by t.occurred_at,t.id),'[]'::jsonb)
  ) into v_previous_day_operations
  from public.transactions t
  left join public.accounts fa on fa.id=t.from_account_id
  left join public.accounts ta on ta.id=t.to_account_id
  where t.occurred_at>=public.finance_day_start(v_today-1)
    and t.occurred_at<public.finance_day_start(v_today);

  return jsonb_build_object(
    'status_version','cashflow_until_next_income_v3','as_of',p_as_of,'business_date',v_today,
    'integrity_ok',coalesce(v_integrity_errors,0)=0,'integrity_issues',v_integrity,
    'cash',jsonb_build_object('actual_cash',l.actual_cash,'breakdown',v_cash),
    'next_income',jsonb_build_object('date',l.next_income_date,'description',l.next_income_description,'amount',l.next_income_amount),
    'weekly_budget',jsonb_build_object('week_start',v_week_start,'budget',v_week_budget,'spend',v_week_spend,'remaining',v_week_remaining,'overrun',v_week_overrun),
    'liquidity',jsonb_build_object(
      'free_cash_until_next_income',l.free_cash_until_next_income,
      'required_outflows_before_income',l.required_outflows_before_income,
      'remaining_living_budget',l.remaining_living_budget,
      'future_living_budget',l.future_living_budget,
      'planned_purchase_reserve',l.planned_purchase_reserve,'credit_reserve',(SELECT coalesce(sum(additional_reserve),0) FROM public.get_credit_cash_reserves(p_as_of,l.next_income_date-1))),
    'previous_day_operations',v_previous_day_operations,
    'today',v_today_events,'controls',v_controls,'obligations_until_next_income',v_future);
end
$function$;
