CREATE OR REPLACE FUNCTION public.get_credit_cash_reserves(p_as_of timestamp with time zone, p_horizon_end date)
 RETURNS TABLE(account_id bigint, unpaid_life numeric, grace_outstanding numeric, scheduled_repayments numeric, additional_reserve numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 WITH grace AS (SELECT reserve_liability_id,sum(CASE reserve_effect WHEN 'grace_draw' THEN amount ELSE -amount END) amount FROM public.transactions WHERE reserve_effect<>'none' AND occurred_at<=p_as_of GROUP BY reserve_liability_id),
 scheduled AS (SELECT e.liability_id,sum(s.cash_still_required) amount FROM public.cash_flow_events e JOIN public.get_cash_flow_event_state_as_of(p_as_of)s ON s.event_id=e.id WHERE e.event_type='debt_payment' AND s.derived_status NOT IN ('executed','cancelled') AND e.event_date<=p_horizon_end GROUP BY e.liability_id)
 SELECT c.account_id,c.unsettled_budget_spend,coalesce(g.amount,0),coalesce(s.amount,0),greatest(c.unsettled_budget_spend+coalesce(g.amount,0)-coalesce(s.amount,0),0)
 FROM public.get_credit_budget_position(p_as_of)c LEFT JOIN public.liabilities l ON l.linked_account_id=c.account_id AND l.balance_model='revolving_account' AND l.status='active'
 LEFT JOIN grace g ON g.reserve_liability_id=l.id LEFT JOIN scheduled s ON s.liability_id=l.id;
$function$;
