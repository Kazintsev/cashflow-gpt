CREATE OR REPLACE FUNCTION public.forecast_free_cash(p_target_date date, p_weekly_living numeric DEFAULT 20000, p_reserve numeric DEFAULT 0)
 RETURNS TABLE(current_free_cash numeric, planned_income numeric, secured_outflows numeric, unsecure_outflows numeric, remaining_living_budget numeric, living_budget_overrun numeric, future_living_budget numeric, projected_free_cash numeric, safe_extra_payment numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 WITH t AS (SELECT * FROM public.get_financial_position_v2(p_target_date,p_weekly_living)),n AS (SELECT * FROM public.get_financial_position_v2(public.finance_business_date(now()),p_weekly_living)) SELECT n.free_cash,t.expected_income,t.secured_future_outflows,t.required_cash_flow_outflows,t.remaining_living_budget,GREATEST(t.current_week_spend-t.current_week_budget,0),t.future_living_budget,t.free_cash,GREATEST(t.free_cash-p_reserve,0) FROM t,n
$function$;
