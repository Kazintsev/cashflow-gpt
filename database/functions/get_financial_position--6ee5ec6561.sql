CREATE OR REPLACE FUNCTION public.get_financial_position(p_as_of timestamp with time zone, p_default_weekly_budget numeric DEFAULT 20000)
 RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 SELECT p_as_of,v.actual_cash,v.projected_cash,v.current_week_budget,v.remaining_living_budget,GREATEST(v.current_week_spend-v.current_week_budget,0),v.planned_purchase_reserve,v.required_cash_flow_outflows,v.secured_future_outflows,v.credit_budget_additional_reserve,v.free_cash FROM public.get_financial_position_at(public.finance_business_date(p_as_of),p_as_of,p_default_weekly_budget) v
$function$;
