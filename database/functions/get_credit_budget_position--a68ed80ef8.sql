CREATE OR REPLACE FUNCTION public.get_credit_budget_position(p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(account_id bigint, account_name text, life_spend_total numeric, cash_repayments_total numeric, unsettled_budget_spend numeric, this_week_life_spend numeric, this_week_cash_repayments numeric, this_week_unsettled numeric, carryover_unsettled numeric, strategic_repayments numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
WITH cfg AS (
 SELECT public.finance_day_start((public.finance_setting_text('tracking_start_date','1970-01-01'))::date) start_ts,date_trunc('week',public.finance_business_date(p_as_of))::date week_start
),cc AS (
 SELECT a.id,a.name FROM public.accounts a WHERE a.is_active AND a.account_type='credit_card'
),mov AS (
 SELECT c.id account_id,t.occurred_at,t.id txid,t.transaction_date,t.amount delta_amount,t.amount life_amount,0::numeric repay_amount
 FROM cc c JOIN public.transactions t ON t.from_account_id=c.id CROSS JOIN cfg
 WHERE t.occurred_at BETWEEN cfg.start_ts AND p_as_of AND t.transaction_type='expense' AND t.budget_effect='life'
 UNION ALL
 SELECT c.id,t.occurred_at,t.id,t.transaction_date,-t.amount,0::numeric,t.amount
 FROM cc c JOIN public.transactions t ON t.to_account_id=c.id JOIN public.accounts fa ON fa.id=t.from_account_id CROSS JOIN cfg
 WHERE t.occurred_at BETWEEN cfg.start_ts AND p_as_of AND fa.account_type IN ('bank','cash') AND t.transaction_type IN ('transfer','debt_payment') AND t.reserve_effect<>'grace_repay'
),run AS (
 SELECT m.*,SUM(delta_amount) OVER(PARTITION BY account_id ORDER BY occurred_at,txid ROWS UNBOUNDED PRECEDING) cs FROM mov m
),stats AS (
 SELECT account_id,MAX(cs) FILTER(WHERE rn_desc=1) final_cs,LEAST(MIN(cs),0) min_cs
 FROM (SELECT r.*,ROW_NUMBER() OVER(PARTITION BY account_id ORDER BY occurred_at DESC,txid DESC) rn_desc FROM run r) z GROUP BY account_id
),agg AS (
 SELECT c.id,c.name,COALESCE(SUM(m.life_amount),0) life_total,COALESCE(SUM(m.repay_amount),0) repay_total,
   COALESCE(s.final_cs,0) final_cs,COALESCE(s.min_cs,0) min_cs,
   COALESCE(SUM(m.life_amount) FILTER(WHERE m.transaction_date BETWEEN cfg.week_start AND public.finance_business_date(p_as_of)),0) week_life,
   COALESCE(SUM(m.repay_amount) FILTER(WHERE m.transaction_date BETWEEN cfg.week_start AND public.finance_business_date(p_as_of)),0) week_repay
 FROM cc c CROSS JOIN cfg LEFT JOIN mov m ON m.account_id=c.id LEFT JOIN stats s ON s.account_id=c.id
 GROUP BY c.id,c.name,cfg.week_start,s.final_cs,s.min_cs
)
SELECT id,name,life_total,repay_total,GREATEST(final_cs-min_cs,0),week_life,week_repay,LEAST(GREATEST(final_cs-min_cs,0),week_life),GREATEST(GREATEST(final_cs-min_cs,0)-LEAST(GREATEST(final_cs-min_cs,0),week_life),0),GREATEST(repay_total-(life_total-GREATEST(final_cs-min_cs,0)),0)
FROM agg
$function$;
