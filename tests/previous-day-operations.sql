-- Disposable test database only. All probe rows roll back; sequences can advance.
BEGIN;
DO $test$
DECLARE
  a bigint; b bigint; r record; s jsonb; ops jsonb;
  cutoff timestamptz := '2026-01-03 08:00:00+03';
  expected_ids bigint[] := '{}'; actual_ids bigint[];
BEGIN
  IF EXISTS (SELECT 1 FROM public.transactions
    WHERE occurred_at >= '2026-01-01 00:00:00+03'::timestamptz
      AND occurred_at < '2026-01-04 00:00:00+03'::timestamptz) THEN
    RAISE EXCEPTION 'Reconciliation probe requires an unused Jan 1-3 2026 fixture window';
  END IF;
  INSERT INTO public.accounts(name,account_type,is_active)
    VALUES ('Reconciliation source','other_asset',false) RETURNING id INTO a;
  INSERT INTO public.accounts(name,account_type)
    VALUES ('Reconciliation target','other_asset') RETURNING id INTO b;
  FOR r IN SELECT * FROM (VALUES
    ('2026-01-01 23:59:59.999999+03'::timestamptz,'expense',false),
    ('2026-01-02 00:00:00+03'::timestamptz,'expense',true),
    ('2026-01-02 12:00:00+03'::timestamptz,'income',true),
    ('2026-01-02 12:00:00+03'::timestamptz,'transfer',true),
    ('2026-01-02 23:59:59.999999+03'::timestamptz,'expense',true),
    ('2026-01-03 00:00:00+03'::timestamptz,'expense',false)
  ) AS f(ts,kind,included) LOOP
    INSERT INTO public.transactions(transaction_date,occurred_at,transaction_type,
      amount,currency,description,budget_effect,from_account_id,to_account_id,created_at)
    VALUES (public.finance_business_date(r.ts),r.ts,r.kind,10,'RUB',
      'Repeated synthetic description',CASE WHEN r.kind='expense' THEN 'excluded' ELSE 'none' END,
      CASE WHEN r.kind<>'income' THEN a END,
      CASE WHEN r.kind IN ('income','transfer') THEN b END,
      '2026-02-01 12:00:00+03');
    IF r.included THEN
      expected_ids:=array_append(expected_ids,currval('public.transactions_id_seq')::bigint);
    END IF;
  END LOOP;
  SET CONSTRAINTS ALL IMMEDIATE;
  -- Session timezone must not determine the reporting date.
  PERFORM set_config('TimeZone','America/Los_Angeles',true);
  s:=public.get_status_until_next_income(cutoff,null)->'previous_day_operations';
  ops:=s->'operations';
  SELECT array_agg((x->>'transaction_id')::bigint ORDER BY ord) INTO actual_ids
    FROM jsonb_array_elements(ops) WITH ORDINALITY AS j(x,ord);
  IF actual_ids IS DISTINCT FROM expected_ids OR (s->>'count')::int<>4
    OR jsonb_array_length(ops)<>4 OR s->>'date'<>'2026-01-02'
    OR s->>'timezone'<>'Europe/Moscow'
    OR (s->>'start_at')::timestamptz<>'2026-01-02 00:00:00+03'::timestamptz
    OR (s->>'end_at_exclusive')::timestamptz<>'2026-01-03 00:00:00+03'::timestamptz
    OR ops->0->>'local_time'<>'00:00:00'
    OR ops->0->>'from_account_name'<>'Reconciliation source'
    OR ops->2->>'transaction_type'<>'transfer'
    OR ops->2->>'to_account_name'<>'Reconciliation target'
    OR (ops->0->>'amount')::numeric<>10 THEN
    RAISE EXCEPTION 'Previous-day boundaries, completeness, ordering or fields failed';
  END IF;
  -- At today's exact midnight, yesterday still contains the complete prior day.
  IF public.get_status_until_next_income('2026-01-03 00:00:00+03'::timestamptz,null)
      ->'previous_day_operations' IS DISTINCT FROM s THEN
    RAISE EXCEPTION 'Midnight reconciliation differs from morning';
  END IF;
  s:=public.get_status_until_next_income('2026-01-01 08:00:00+03'::timestamptz,null)
    ->'previous_day_operations';
  IF s->>'date'<>'2025-12-31' OR (s->>'count')::int<>0 OR s->'operations'<>'[]'::jsonb THEN
    RAISE EXCEPTION 'Empty previous day/year boundary failed';
  END IF;
END $test$;
ROLLBACK;
