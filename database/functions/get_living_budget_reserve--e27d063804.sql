CREATE OR REPLACE FUNCTION public.get_living_budget_reserve(p_week_start date, p_as_of timestamp with time zone, p_default_budget numeric DEFAULT NULL::numeric)
 RETURNS TABLE(budget_amount numeric, spent_amount numeric, earmarked_amount numeric, remaining_reserve numeric, overrun numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 WITH b AS (SELECT coalesce((SELECT amount FROM public.living_budgets WHERE week_start=p_week_start),p_default_budget,public.finance_setting_numeric('default_weekly_budget',20000)) amount),
 spent AS (SELECT coalesce(sum(amount),0) amount FROM public.transactions WHERE budget_effect='life' AND transaction_date>=p_week_start AND transaction_date<p_week_start+7 AND occurred_at<=p_as_of),
 earmarked AS (SELECT coalesce(sum(greatest(s.funded_amount-s.paid_amount,0)),0) amount FROM public.cash_flow_events e JOIN public.get_cash_flow_event_state_as_of(p_as_of)s ON s.event_id=e.id WHERE e.event_type IN ('expense','planned_expense') AND NOT e.living_budget_exempt AND s.derived_status<>'cancelled' AND e.event_date>=p_week_start AND e.event_date<p_week_start+7)
 SELECT b.amount,spent.amount,earmarked.amount,greatest(b.amount-spent.amount-earmarked.amount,0),greatest(spent.amount-b.amount,0) FROM b,spent,earmarked;
$function$;
