CREATE OR REPLACE FUNCTION public.normalize_transaction_budget_effect()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
IF TG_OP='UPDATE' THEN
 IF NEW.occurred_at IS DISTINCT FROM OLD.occurred_at AND NEW.transaction_date IS NOT DISTINCT FROM OLD.transaction_date THEN NEW.transaction_date:=public.finance_business_date(NEW.occurred_at);
 ELSIF NEW.transaction_date IS DISTINCT FROM OLD.transaction_date AND NEW.occurred_at IS NOT DISTINCT FROM OLD.occurred_at THEN
 NEW.occurred_at:=(NEW.transaction_date+(OLD.occurred_at AT TIME ZONE public.finance_setting_text('business_timezone','Europe/Moscow'))::time) AT TIME ZONE public.finance_setting_text('business_timezone','Europe/Moscow');
 END IF;
END IF;
IF NEW.occurred_at IS NULL THEN NEW.occurred_at:=COALESCE(public.finance_day_start(NEW.transaction_date)+interval '12 hours',now());END IF;IF NEW.transaction_date IS NULL THEN NEW.transaction_date:=public.finance_business_date(NEW.occurred_at);END IF;IF NEW.budget_effect IS NULL THEN NEW.budget_effect:=CASE WHEN NEW.transaction_type='expense' THEN 'life' ELSE 'none' END;END IF;IF NEW.transaction_type<>'expense' AND NEW.budget_effect='life' THEN NEW.budget_effect:='none';END IF;IF NEW.transaction_type='income' AND NEW.salary_component IS NULL THEN IF NEW.description ILIKE '%аванс%' THEN NEW.salary_component:='advance';ELSIF NEW.description ILIKE '%отпускн%' THEN NEW.salary_component:='vacation';ELSIF NEW.description ILIKE '%зарплат%' THEN NEW.salary_component:='salary';END IF;END IF;IF NEW.salary_component IN ('advance','vacation') AND NEW.salary_period_start IS NULL THEN NEW.salary_period_start:=date_trunc('month',NEW.transaction_date)::date;END IF;IF NEW.salary_component='salary' AND NEW.salary_period_start IS NULL THEN NEW.salary_period_start:=date_trunc('month',NEW.transaction_date-interval '1 month')::date;END IF;
IF NEW.transaction_date<>public.finance_business_date(NEW.occurred_at) THEN RAISE EXCEPTION 'transaction_date must match occurred_at in business timezone'; END IF;
IF NEW.transaction_type<>'income' THEN NEW.salary_component:=NULL;NEW.salary_period_start:=NULL;NEW.income_event_id:=NULL;
ELSIF NEW.salary_component IN ('advance','salary') THEN
 IF TG_OP='INSERT' OR NEW.salary_component IS DISTINCT FROM OLD.salary_component OR NEW.salary_period_start IS DISTINCT FROM OLD.salary_period_start OR NEW.income_event_id IS NULL THEN
 SELECT e.id INTO NEW.income_event_id FROM public.cash_flow_events e JOIN public.cash_flow_rules r ON r.id=e.rule_id
 WHERE e.event_type='income' AND e.status<>'cancelled' AND e.period_start=NEW.salary_period_start
 AND r.rule_type=CASE NEW.salary_component WHEN 'advance' THEN 'salary_advance' ELSE 'salary_balance' END ORDER BY e.id LIMIT 1;
 END IF;
END IF;
RETURN NEW;END $function$;
