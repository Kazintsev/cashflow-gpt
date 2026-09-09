-- Synthetic example. Optional; use only on a fresh installation.
BEGIN;
DO $demo$
DECLARE
  bank_id bigint; cash_id bigint; buffer_id bigint; card_id bigint;
  loan_id bigint; food_id bigint; debt_category_id bigint; event_id bigint;
  v_today date := public.finance_business_date(now());
  table_name text; occupied boolean;
BEGIN
  FOR table_name IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r' LOOP
    EXECUTE format('SELECT EXISTS(SELECT 1 FROM public.%I)',table_name) INTO occupied;
    IF occupied THEN RAISE EXCEPTION 'demo requires empty tables; % contains data',table_name; END IF;
  END LOOP;
  INSERT INTO public.finance_settings(key,value) VALUES
    ('business_timezone','"Europe/Moscow"'),
    ('default_weekly_budget','10000'),
    ('monthly_salary','60000'),
    ('tracking_start_date',to_jsonb(v_today::text));
  INSERT INTO public.accounts(name,account_type,opening_balance,opening_balance_date)
    VALUES('Demo Bank','bank',30000,v_today) RETURNING id INTO bank_id;
  INSERT INTO public.accounts(name,account_type,opening_balance,opening_balance_date)
    VALUES('Demo Cash','cash',10000,v_today) RETURNING id INTO cash_id;
  INSERT INTO public.accounts(name,account_type,opening_balance,opening_balance_date)
    VALUES('Demo Buffer','payment_buffer',0,v_today) RETURNING id INTO buffer_id;
  INSERT INTO public.accounts(name,account_type,opening_balance,opening_balance_date)
    VALUES('Demo Card','credit_card',0,v_today) RETURNING id INTO card_id;
  INSERT INTO public.categories(name,category_type) VALUES('Demo Food','expense') RETURNING id INTO food_id;
  INSERT INTO public.categories(name,category_type) VALUES('Demo Debt','debt') RETURNING id INTO debt_category_id;
  INSERT INTO public.liabilities(account_id,name,liability_type,balance_model,payment_account_id,annual_rate)
    VALUES(buffer_id,'Demo Loan','consumer_loan','installment',buffer_id,12) RETURNING id INTO loan_id;
  INSERT INTO public.liability_balance_snapshots(liability_id,balance_as_of,principal_balance)
    VALUES(loan_id,public.finance_day_start(v_today),5000);
  INSERT INTO public.liabilities(account_id,name,liability_type,balance_model,linked_account_id)
    VALUES(card_id,'Demo Card Debt','credit_card','revolving_account',card_id);
  INSERT INTO public.cash_flow_events(event_date,event_type,amount,description,account_id)
    VALUES(v_today+10,'income',60000,'Demo Income',bank_id);
  INSERT INTO public.cash_flow_events(event_date,event_type,amount,description,account_id,liability_id,living_budget_exempt)
    VALUES(v_today+2,'debt_payment',800,'Demo Loan Payment',buffer_id,loan_id,true) RETURNING id INTO event_id;
  PERFORM public.finance_command('demo-lunch','record_transaction',jsonb_build_object(
    'transaction_type','expense','amount',450,'description','Demo Lunch',
    'from_account_id',bank_id,'category_id',food_id,'occurred_at',now(),'budget_effect','life'));
  PERFORM public.finance_command('demo-funding','fund_event',jsonb_build_object(
    'event_id',event_id,'from_account_id',bank_id,'amount',800,'occurred_at',now()));
END $demo$;
SET CONSTRAINTS ALL IMMEDIATE;
COMMIT;
