-- Run as the owner, ONLY in a disposable database with today's unchanged demo seed.
-- All probe changes roll back in a subtransaction. Sequence values may advance.
-- Raises an error on any failed assertion; returns the passed check names on success.
DO $smoke$
DECLARE
  passed text[] := ARRAY[]::text[];
  s jsonb; before_s jsonb; after_s jsonb; payload jsonb;
  expected jsonb := '{"tables":19,"views":4,"functions":76,"sequences":18,"constraints":144,"additional_indexes":43,"triggers":53}';
  actual jsonb; obj record; role_name text;
  bank bigint; cash bigint; card bigint; buffer_account bigint;
  food bigint; v_event_id bigint; loan bigint; tx bigint; anchor_account bigint;
  free_before numeric; spend_before numeric; principal numeric;
  rejected boolean; saved_amount numeric;
BEGIN
  PERFORM set_config('plpgsql.check_asserts','on',true);
  BEGIN
    s := public.get_status_until_next_income(now(),NULL);
    ASSERT (s#>>'{cash,actual_cash}')::numeric=38750, 'requires unchanged demo cash';
    ASSERT (s#>>'{weekly_budget,spend}')::numeric=450, 'requires today demo spend';
    ASSERT (s#>>'{weekly_budget,budget}')::numeric=10000, 'demo budget';
    ASSERT (s->>'integrity_ok')::boolean, 'demo integrity';
    ASSERT (SELECT count(*) FROM public.transactions)=2, 'requires pristine demo transactions';
    passed := array_append(passed,'demo_status');

    SELECT jsonb_build_object(
      'tables',(SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='r'),
      'views',(SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='v'),
      'sequences',(SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='S'),
      'functions',(SELECT count(*) FROM pg_proc WHERE pronamespace='public'::regnamespace),
      'constraints',(SELECT count(*) FROM pg_constraint WHERE connamespace='public'::regnamespace AND contype<>'n'),
      'triggers',(SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE c.relnamespace='public'::regnamespace AND NOT t.tgisinternal),
      'additional_indexes',(SELECT count(*) FROM pg_index i JOIN pg_class c ON c.oid=i.indrelid WHERE c.relnamespace='public'::regnamespace AND NOT EXISTS(SELECT 1 FROM pg_constraint co WHERE co.conindid=i.indexrelid))
    ) INTO actual;
    ASSERT actual=expected, 'schema inventory mismatch';
    passed := array_append(passed,'schema_inventory');

    PERFORM set_config('check_function_bodies','on',true);
    FOR obj IN SELECT pg_get_functiondef(oid) definition FROM pg_proc WHERE pronamespace='public'::regnamespace LOOP
      EXECUTE obj.definition;
    END LOOP;
    passed := array_append(passed,'compile_76_functions');

    ASSERT NOT EXISTS(SELECT 1 FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='r' AND NOT relrowsecurity), 'RLS disabled';
    ASSERT NOT EXISTS(SELECT 1 FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='v' AND NOT coalesce(reloptions @> ARRAY['security_invoker=true'],false)), 'view not invoker';
    FOREACH role_name IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
      FOR obj IN SELECT oid FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind IN ('r','v') LOOP
        ASSERT NOT has_table_privilege(role_name,obj.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'), 'unexpected client table privilege';
      END LOOP;
      FOR obj IN SELECT oid FROM pg_proc WHERE pronamespace='public'::regnamespace LOOP
        ASSERT NOT has_function_privilege(role_name,obj.oid,'EXECUTE'), 'unexpected client execute privilege';
      END LOOP;
      FOR obj IN SELECT oid FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='S' LOOP
        ASSERT NOT has_sequence_privilege(role_name,obj.oid,'USAGE,SELECT,UPDATE'), 'unexpected sequence privilege';
      END LOOP;
    END LOOP;
    EXECUTE 'SET LOCAL ROLE anon';
    rejected := false;
    BEGIN
      PERFORM 1 FROM public.transactions;
    EXCEPTION WHEN insufficient_privilege THEN rejected := true;
    END;
    EXECUTE 'RESET ROLE';
    ASSERT rejected, 'anonymous read was allowed';
    passed := array_append(passed,'owner_only_access');

    SELECT id INTO STRICT bank FROM public.accounts WHERE name='Demo Bank';
    SELECT id INTO STRICT cash FROM public.accounts WHERE name='Demo Cash';
    SELECT id INTO STRICT card FROM public.accounts WHERE name='Demo Card';
    SELECT id INTO STRICT buffer_account FROM public.accounts WHERE name='Demo Buffer';
    SELECT id INTO STRICT food FROM public.categories WHERE name='Demo Food';
    SELECT id INTO STRICT v_event_id FROM public.cash_flow_events WHERE description='Demo Loan Payment';
    SELECT id INTO STRICT loan FROM public.liabilities WHERE name='Demo Loan';
    SELECT id,request_payload INTO STRICT tx,payload FROM public.transactions WHERE external_ref='demo-lunch';
    ASSERT public.finance_command('demo-lunch',payload->>'command',payload->'args')=tx, 'retry ID changed';
    rejected := false;
    BEGIN
      PERFORM public.finance_command('demo-lunch',payload->>'command',jsonb_set(payload->'args','{amount}','999'));
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE '%different arguments%' THEN RAISE; END IF;
      rejected := true;
    END;
    ASSERT rejected, 'changed retry accepted';
    ASSERT (SELECT count(*) FROM public.transactions WHERE external_ref='demo-lunch')=1, 'retry duplicated';
    passed := array_append(passed,'request_idempotency');

    free_before := public.get_free_cash(now());
    ASSERT (SELECT derived_status='secured' AND paid_amount=0 FROM public.get_cash_flow_event_state_as_of(now()) e WHERE e.event_id=v_event_id), 'funding state';
    PERFORM public.finance_command('native-execute','execute_event',jsonb_build_object('event_id',v_event_id,'amount',800,'occurred_at',now(),'principal_amount',700,'interest_amount',100,'fee_amount',0));
    SET CONSTRAINTS ALL IMMEDIATE;
    ASSERT public.get_free_cash(now())=free_before, 'buffer deducted twice';
    ASSERT public.get_account_balance(buffer_account,now())=0, 'buffer balance';
    SELECT principal_balance INTO principal FROM public.get_liability_balance(loan,now());
    ASSERT principal=4300, 'principal/interest split';
    ASSERT (SELECT e.derived_status='executed' FROM public.get_cash_flow_event_state_as_of(now()) e WHERE e.event_id=v_event_id), 'execution state';
    rejected := false;
    BEGIN
      PERFORM public.finance_command('native-overpay','execute_event',jsonb_build_object('event_id',v_event_id,'amount',1));
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE '%exceeds remaining%' AND SQLERRM NOT LIKE '%no remaining%' THEN RAISE; END IF;
      rejected := true;
    END;
    ASSERT rejected, 'overpayment accepted';
    passed := array_append(passed,'funding_execution_principal');

    before_s := public.get_status_until_next_income(now(),NULL);
    PERFORM public.finance_command('native-transfer','record_transaction',jsonb_build_object('transaction_type','transfer','amount',500,'description','Native transfer','from_account_id',bank,'to_account_id',cash,'occurred_at',now()));
    after_s := public.get_status_until_next_income(now(),NULL);
    ASSERT after_s#>'{cash,actual_cash}'=before_s#>'{cash,actual_cash}', 'transfer cash';
    ASSERT after_s#>'{weekly_budget,spend}'=before_s#>'{weekly_budget,spend}', 'transfer budget';
    PERFORM public.finance_command('native-excluded','record_transaction',jsonb_build_object('transaction_type','expense','amount',300,'description','Native excluded','from_account_id',bank,'budget_effect','excluded','occurred_at',now()));
    after_s := public.get_status_until_next_income(now(),NULL);
    ASSERT (after_s#>>'{cash,actual_cash}')::numeric=(before_s#>>'{cash,actual_cash}')::numeric-300, 'excluded cash';
    ASSERT after_s#>'{weekly_budget,spend}'=before_s#>'{weekly_budget,spend}', 'excluded budget';
    passed := array_append(passed,'transfer_and_excluded');

    before_s := public.get_status_until_next_income(now(),NULL);
    PERFORM public.finance_command('native-card-buy','record_transaction',jsonb_build_object('transaction_type','expense','amount',600,'description','Native card buy','from_account_id',card,'category_id',food,'budget_effect','life','occurred_at',now()));
    after_s := public.get_status_until_next_income(now(),NULL);
    ASSERT after_s#>'{cash,actual_cash}'=before_s#>'{cash,actual_cash}', 'card buy cash';
    ASSERT (after_s#>>'{weekly_budget,spend}')::numeric=(before_s#>>'{weekly_budget,spend}')::numeric+600, 'card buy budget';
    ASSERT (SELECT unsettled_budget_spend FROM public.get_credit_budget_position(now()) WHERE account_id=card)=600, 'card reserve';
    PERFORM public.finance_command('native-card-repay','record_transaction',jsonb_build_object('transaction_type','transfer','amount',600,'description','Native card repay','from_account_id',bank,'to_account_id',card,'occurred_at',now()));
    after_s := public.get_status_until_next_income(now(),NULL);
    ASSERT (after_s#>>'{cash,actual_cash}')::numeric=(before_s#>>'{cash,actual_cash}')::numeric-600, 'card repay cash';
    ASSERT (after_s#>>'{weekly_budget,spend}')::numeric=(before_s#>>'{weekly_budget,spend}')::numeric+600, 'card expense duplicated';
    ASSERT (SELECT unsettled_budget_spend FROM public.get_credit_budget_position(now()) WHERE account_id=card)=0, 'card reserve not closed';
    passed := array_append(passed,'credit_card_budget_and_repayment');

    PERFORM public.correct_finance_transaction(tx,'{}',jsonb_build_array(jsonb_build_object('category_id',food,'amount',450)));
    SET CONSTRAINTS ALL DEFERRED;
    rejected := false;
    BEGIN
      PERFORM public.correct_finance_transaction(tx,'{"amount":451}');
      SET CONSTRAINTS ALL IMMEDIATE;
    EXCEPTION WHEN check_violation OR raise_exception THEN
      IF SQLERRM NOT LIKE '%allocation%' AND SQLERRM NOT LIKE '%согласован%' THEN RAISE; END IF;
      rejected := true;
    END;
    ASSERT rejected, 'inconsistent correction accepted';
    SELECT amount INTO saved_amount FROM public.transactions WHERE id=tx;
    ASSERT saved_amount=450, 'failed correction was not rolled back';
    PERFORM public.correct_finance_transaction(tx,jsonb_build_object('amount',460,'from_account_id',cash),jsonb_build_array(jsonb_build_object('category_id',food,'amount',460)));
    SET CONSTRAINTS ALL IMMEDIATE;
    ASSERT (SELECT amount FROM public.transaction_category_allocations WHERE transaction_id=tx)=460, 'correction allocation';
    ASSERT (SELECT from_account_id FROM public.transactions WHERE id=tx)=cash, 'correction account';
    passed := array_append(passed,'atomic_correction_and_deferred_constraints');

    INSERT INTO public.accounts(name,account_type) VALUES('Native Anchor','other_asset') RETURNING id INTO anchor_account;
    INSERT INTO public.account_balance_snapshots(account_id,balance_date,balance_as_of,balance) VALUES(anchor_account,'2026-01-05','2026-01-05T10:00:00+03',15000);
    PERFORM public.finance_command('native-anchor-equal','record_transaction',jsonb_build_object('transaction_type','expense','amount',20,'description','Native exact anchor','from_account_id',anchor_account,'budget_effect','excluded','occurred_at','2026-01-05T10:00:00+03'));
    PERFORM public.finance_command('native-anchor-after','record_transaction',jsonb_build_object('transaction_type','expense','amount',300,'description','Native after anchor','from_account_id',anchor_account,'budget_effect','excluded','occurred_at','2026-01-05T10:10:00+03'));
    ASSERT public.get_account_balance(anchor_account,'2026-01-05T10:05:00+03'::timestamptz)=15000, 'snapshot equal cutoff';
    ASSERT public.get_account_balance(anchor_account,'2026-01-05T10:15:00+03'::timestamptz)=14700, 'snapshot subsequent transaction';
    passed := array_append(passed,'snapshot_cutoff');

    SELECT to_jsonb(p) INTO s FROM public.get_financial_position_at(public.finance_business_date(now())+15,now(),NULL) p;
    ASSERT s->>'free_cash' IS NOT NULL, 'forecast missing cash';
    s := public.get_status_until_next_income(now(),NULL);
    ASSERT (s->>'integrity_ok')::boolean, 'final integrity';
    SET CONSTRAINTS ALL IMMEDIATE;
    passed := array_append(passed,'forecast_and_integrity');
    RAISE EXCEPTION USING ERRCODE='Z9999',MESSAGE='rollback successful smoke probes';
  EXCEPTION WHEN SQLSTATE 'Z9999' THEN NULL;
  END;
  ASSERT cardinality(passed)=11, 'incomplete check suite';
  ASSERT (SELECT count(*) FROM public.transactions)=2, 'probe writes survived rollback';
  ASSERT NOT EXISTS(SELECT 1 FROM public.accounts WHERE name='Native Anchor'), 'probe account survived rollback';
  passed := array_append(passed,'probe_rollback');
  PERFORM set_config('cashflow_test.result',to_jsonb(passed)::text,true);
END $smoke$;
SELECT current_setting('cashflow_test.result')::jsonb AS passed_checks;
