CREATE OR REPLACE FUNCTION public.generate_cash_flow_events(from_date date, to_date date)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  r record; period date; d date; amt numeric; monthly_salary numeric; adv numeric; vacation numeric; adv_rule bigint; skey text;v_seen text[]:=ARRAY[]::text[];v_obsolete record;
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
  IF to_date<from_date THEN RAISE EXCEPTION 'to_date must be >= from_date'; END IF;
  monthly_salary:=public.finance_setting_numeric('monthly_salary',NULL);
  IF monthly_salary IS NULL AND EXISTS (
    SELECT 1 FROM public.cash_flow_rules WHERE is_active
      AND rule_type IN ('salary_advance','salary_balance')
  ) THEN
    RAISE EXCEPTION 'monthly_salary must be configured before generating salary events';
  END IF;
  SELECT id INTO adv_rule FROM public.cash_flow_rules WHERE rule_type='salary_advance' AND is_active ORDER BY id LIMIT 1;

  FOR r IN SELECT * FROM public.cash_flow_rules WHERE is_active ORDER BY CASE rule_type WHEN 'salary_advance' THEN 1 WHEN 'salary_balance' THEN 2 ELSE 0 END,id LOOP
    IF r.schedule_type='weekly' THEN
      IF r.payment_day IS NULL OR r.payment_day<1 OR r.payment_day>7 THEN
        RAISE EXCEPTION 'weekly rule % requires payment_day 1..7 (ISO weekday)',r.id;
      END IF;
      d:=from_date + ((r.payment_day-EXTRACT(ISODOW FROM from_date)::int+7)%7);
      WHILE d<=to_date LOOP
        IF (r.start_date IS NULL OR d>=r.start_date) AND (r.end_date IS NULL OR d<=r.end_date) THEN
          amt:=r.amount;
          skey:='rule:'||r.id::text||':'||d::text;v_seen:=array_append(v_seen,skey);
          INSERT INTO public.cash_flow_events(
            event_date,event_type,amount,description,account_id,liability_id,is_planned,is_secured,rule_id,period_start,period_end,
            calculation_method,living_budget_exempt,status,source_type,source_key,fulfillment_mode
          ) VALUES(
            d,r.event_type,amt,r.name,r.account_id,r.liability_id,true,false,r.id,d,d,
            r.calculation_method,r.living_budget_exempt,'planned','rule',skey,'dated_payment'
          )
          ON CONFLICT(source_key) WHERE source_key IS NOT NULL DO UPDATE SET
            event_date=EXCLUDED.event_date,event_type=EXCLUDED.event_type,
            amount=CASE WHEN public.cash_flow_events.status IN ('planned','partially_secured','secured') THEN EXCLUDED.amount ELSE public.cash_flow_events.amount END,
            description=EXCLUDED.description,account_id=coalesce(EXCLUDED.account_id,public.cash_flow_events.account_id),liability_id=EXCLUDED.liability_id,rule_id=EXCLUDED.rule_id,
            period_start=EXCLUDED.period_start,period_end=EXCLUDED.period_end,calculation_method=EXCLUDED.calculation_method,
            living_budget_exempt=EXCLUDED.living_budget_exempt,source_type='rule',fulfillment_mode='dated_payment' WHERE public.cash_flow_events.status NOT IN ('executed','partially_executed','cancelled');
        END IF;
        d:=d+7;
      END LOOP;
      CONTINUE;
    END IF;

    period:=date_trunc('month',from_date-interval '1 month')::date;
    WHILE period<=date_trunc('month',to_date)::date LOOP
      IF r.rule_type='salary_balance' THEN
        d:=make_date(EXTRACT(YEAR FROM period+interval '1 month')::int,EXTRACT(MONTH FROM period+interval '1 month')::int,
          LEAST(COALESCE(r.payment_day,5),EXTRACT(DAY FROM (date_trunc('month',period+interval '1 month')+interval '1 month - 1 day'))::int));
      ELSE
        d:=make_date(EXTRACT(YEAR FROM period)::int,EXTRACT(MONTH FROM period)::int,
          LEAST(COALESCE(r.payment_day,1),EXTRACT(DAY FROM (date_trunc('month',period)+interval '1 month - 1 day'))::int));
      END IF;
      IF r.weekend_rule='previous_business_day' THEN d:=public.business_day_on_or_before(d); END IF;

      IF d BETWEEN from_date AND to_date AND (r.start_date IS NULL OR d>=r.start_date)
         AND (r.end_date IS NULL OR d<=r.end_date) THEN
        IF r.rule_type='salary_advance' THEN
          amt:=ROUND(monthly_salary*COALESCE(r.share_of_monthly_salary,0.5),2);
        ELSIF r.rule_type='salary_balance' THEN
          SELECT COALESCE(SUM(t.amount),0) INTO adv FROM public.transactions t
          WHERE t.transaction_type='income' AND t.salary_component='advance' AND t.salary_period_start=period;
          IF adv=0 THEN
            SELECT COALESCE(MAX(CASE WHEN e.status='executed' AND e.actual_amount IS NOT NULL THEN e.actual_amount ELSE e.amount END),0)
            INTO adv FROM public.cash_flow_events e WHERE e.rule_id=adv_rule AND e.period_start=period AND e.status<>'cancelled';
          END IF;
          IF adv=0 THEN adv:=ROUND(monthly_salary*0.5,2); END IF;
          SELECT COALESCE(SUM(t.amount),0) INTO vacation FROM public.transactions t
          WHERE t.transaction_type='income' AND t.salary_component='vacation' AND t.salary_period_start=period;
          amt:=GREATEST(monthly_salary-adv-vacation,0);
        ELSE
          amt:=r.amount;
        END IF;

        skey:='rule:'||r.id::text||':'||period::text;v_seen:=array_append(v_seen,skey);
        INSERT INTO public.cash_flow_events(
          event_date,event_type,amount,description,account_id,liability_id,is_planned,is_secured,rule_id,period_start,period_end,
          calculation_method,living_budget_exempt,status,source_type,source_key,fulfillment_mode
        ) VALUES(
          d,r.event_type,amt,r.name,r.account_id,r.liability_id,true,false,r.id,period,(period+interval '1 month - 1 day')::date,
          r.calculation_method,r.living_budget_exempt,'planned','rule',skey,'dated_payment'
        )
        ON CONFLICT(source_key) WHERE source_key IS NOT NULL DO UPDATE SET
          event_date=EXCLUDED.event_date,event_type=EXCLUDED.event_type,
          amount=CASE WHEN public.cash_flow_events.status IN ('planned','partially_secured','secured') THEN EXCLUDED.amount ELSE public.cash_flow_events.amount END,
          description=EXCLUDED.description,account_id=coalesce(EXCLUDED.account_id,public.cash_flow_events.account_id),liability_id=EXCLUDED.liability_id,rule_id=EXCLUDED.rule_id,
          period_start=EXCLUDED.period_start,period_end=EXCLUDED.period_end,calculation_method=EXCLUDED.calculation_method,
          living_budget_exempt=EXCLUDED.living_budget_exempt,source_type='rule',fulfillment_mode='dated_payment' WHERE public.cash_flow_events.status NOT IN ('executed','partially_executed','cancelled');
      END IF;
      period:=(period+interval '1 month')::date;
    END LOOP;
  END LOOP;

  FOR r IN
    SELECT s.*,l.name liability_name,l.payment_account_id
    FROM public.liability_payment_schedule s JOIN public.liabilities l ON l.id=s.liability_id
    WHERE l.status='active' AND l.balance_model='installment' AND s.payment_date BETWEEN from_date AND to_date AND s.total_amount>0
    ORDER BY s.payment_date,s.id
  LOOP
    skey:='bank_schedule:'||r.liability_id::text||':'||r.payment_date::text;v_seen:=array_append(v_seen,skey);
    INSERT INTO public.cash_flow_events(
      event_date,event_type,amount,description,account_id,liability_id,is_planned,is_secured,period_start,period_end,calculation_method,
      living_budget_exempt,status,source_type,source_key,fulfillment_mode,liability_payment_schedule_id
    ) VALUES(
      r.payment_date,'debt_payment',r.total_amount,r.liability_name,r.payment_account_id,r.liability_id,true,false,r.payment_date,r.payment_date,
      'bank_schedule',true,'planned','bank_schedule',skey,'dated_payment',r.id
    )
    ON CONFLICT(source_key) WHERE source_key IS NOT NULL DO UPDATE SET
      event_date=EXCLUDED.event_date,
      amount=CASE WHEN public.cash_flow_events.status IN ('planned','partially_secured','secured') THEN EXCLUDED.amount ELSE public.cash_flow_events.amount END,
      description=EXCLUDED.description,account_id=coalesce(EXCLUDED.account_id,public.cash_flow_events.account_id),liability_id=EXCLUDED.liability_id,
      period_start=EXCLUDED.period_start,period_end=EXCLUDED.period_end,calculation_method='bank_schedule',living_budget_exempt=true,
      source_type='bank_schedule',fulfillment_mode='dated_payment',liability_payment_schedule_id=EXCLUDED.liability_payment_schedule_id WHERE public.cash_flow_events.status NOT IN ('executed','partially_executed','cancelled');
  END LOOP;
 FOR v_obsolete IN SELECT e.id FROM public.cash_flow_events e WHERE e.source_type IN ('rule','bank_schedule') AND e.source_key IS NOT NULL
 AND e.event_date BETWEEN from_date AND to_date AND e.status NOT IN ('executed','partially_executed','cancelled') AND NOT(e.source_key=ANY(v_seen)) LOOP
  IF EXISTS(SELECT 1 FROM public.cash_flow_event_funding WHERE cash_flow_event_id=v_obsolete.id) THEN RAISE EXCEPTION 'event % has allocations: reconcile funding before removing its source',v_obsolete.id;END IF;
  UPDATE public.cash_flow_events SET status='cancelled' WHERE id=v_obsolete.id;
 END LOOP;
 UPDATE public.transactions t SET income_event_id=e.id FROM public.cash_flow_events e JOIN public.cash_flow_rules sr ON sr.id=e.rule_id
 WHERE t.transaction_type='income' AND t.income_event_id IS NULL AND e.event_type='income' AND e.status<>'cancelled'
 AND e.period_start=t.salary_period_start AND ((t.salary_component='advance' AND sr.rule_type='salary_advance') OR (t.salary_component='salary' AND sr.rule_type='salary_balance'));

END
$function$;
