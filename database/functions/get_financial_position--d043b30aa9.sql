CREATE OR REPLACE FUNCTION public.get_financial_position(p_as_of date, p_default_weekly_budget numeric DEFAULT 20000)
 RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT * FROM public.get_financial_position(public.finance_day_end(p_as_of),p_default_weekly_budget) $function$;
