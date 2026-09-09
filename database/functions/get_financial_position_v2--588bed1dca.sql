CREATE OR REPLACE FUNCTION public.get_financial_position_v2(p_as_of date, p_default_weekly_budget numeric DEFAULT NULL::numeric)
 RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 RETURN QUERY SELECT * FROM public.get_financial_position_at(p_as_of,
 CASE WHEN p_as_of<public.finance_business_date(now()) THEN public.finance_day_end(p_as_of) ELSE now() END,p_default_weekly_budget);
END
$function$;
