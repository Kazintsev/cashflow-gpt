CREATE OR REPLACE FUNCTION public.get_financial_position_at(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric DEFAULT NULL::numeric)
 RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_now_ts timestamptz:=p_cutoff;v_today date:=public.finance_business_date(v_now_ts);v_cutoff timestamptz;v_anchor_date date;v_week_start date;v_budget numeric;v_spend numeric;v_remain numeric;v_future_budget numeric:=0;v_w date;v_wb numeric;v_income numeric:=0;v_outflows numeric:=0;v_secured numeric:=0;v_projected numeric;v_card_reserve numeric:=0;v_card_additional numeric:=0;v_purchases numeric:=0;r record;v_scheduled numeric;v_actual_cash numeric;
BEGIN
 v_cutoff:=p_cutoff;
 v_anchor_date:=public.finance_business_date(v_cutoff);v_week_start:=date_trunc('week',v_anchor_date)::date;
 SELECT public.get_actual_cash(v_cutoff) INTO v_actual_cash;
 v_budget:=COALESCE((SELECT lb.amount FROM public.living_budgets lb WHERE lb.week_start=v_week_start),p_default_weekly_budget,public.finance_setting_numeric('default_weekly_budget',20000));
 SELECT COALESCE(SUM(t.amount),0) INTO v_spend FROM public.transactions t WHERE t.budget_effect='life' AND t.occurred_at<=v_cutoff AND t.transaction_date BETWEEN v_week_start AND v_anchor_date;
 SELECT remaining_reserve INTO v_remain FROM public.get_living_budget_reserve(v_week_start,v_cutoff,p_default_weekly_budget);
 IF p_as_of>=v_today THEN
   SELECT COALESCE(SUM(i.remaining_amount),0) INTO v_income FROM public.cash_flow_events e JOIN public.get_income_event_state_as_of(v_cutoff) i ON i.event_id=e.id WHERE i.derived_status NOT IN ('cancelled','executed') AND e.event_date BETWEEN v_today AND p_as_of;
   SELECT COALESCE(SUM(s.cash_still_required),0),COALESCE(SUM(s.amount) FILTER(WHERE s.cash_still_required=0 AND s.remaining_payment_amount>0),0)
   INTO v_outflows,v_secured
   FROM public.get_cash_flow_event_state_as_of(v_now_ts) s
   JOIN public.cash_flow_events e ON e.id=s.event_id
   WHERE s.event_type IN ('expense','debt_payment','planned_expense')
     AND s.event_date<=p_as_of AND s.derived_status<>'cancelled'
     AND (s.event_type='debt_payment' OR e.living_budget_exempt);
   v_w:=date_trunc('week',v_today)::date+7;
   WHILE v_w<=p_as_of LOOP
     SELECT COALESCE((SELECT lb.amount FROM public.living_budgets lb WHERE lb.week_start=v_w),COALESCE(p_default_weekly_budget,public.finance_setting_numeric('default_weekly_budget',20000))) INTO v_wb;
     SELECT remaining_reserve INTO v_wb FROM public.get_living_budget_reserve(v_w,v_cutoff,p_default_weekly_budget);v_future_budget:=v_future_budget+v_wb;v_w:=v_w+7;
   END LOOP;
 ELSE
   SELECT COALESCE(SUM(s.cash_still_required),0),COALESCE(SUM(s.amount) FILTER(WHERE s.cash_still_required=0 AND s.remaining_payment_amount>0),0)
   INTO v_outflows,v_secured
   FROM public.get_cash_flow_event_state_as_of(v_cutoff) s
   JOIN public.cash_flow_events e ON e.id=s.event_id
   WHERE s.event_type IN ('expense','debt_payment','planned_expense')
     AND s.event_date<=p_as_of AND s.derived_status<>'cancelled'
     AND (s.event_type='debt_payment' OR e.living_budget_exempt);
 END IF;
 v_projected:=v_actual_cash+v_income-v_outflows;
 SELECT coalesce(sum(unpaid_life+grace_outstanding),0),coalesce(sum(additional_reserve),0) INTO v_card_reserve,v_card_additional FROM public.get_credit_cash_reserves(v_cutoff,p_as_of);

 SELECT COALESCE(SUM(pp.planned_amount),0) INTO v_purchases FROM public.planned_purchases pp WHERE pp.created_at<=v_cutoff AND pp.status<>'cancelled' AND (pp.closed_at IS NULL OR pp.closed_at>v_cutoff);
 RETURN QUERY SELECT p_as_of,v_actual_cash,v_income,v_outflows,v_secured,v_projected,v_budget,v_spend,v_remain,v_future_budget,v_card_reserve,v_card_additional,v_purchases,v_projected-v_remain-v_future_budget-v_card_additional-v_purchases;
END
$function$;
