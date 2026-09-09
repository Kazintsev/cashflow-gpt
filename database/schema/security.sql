-- Owner-only installation. No client role is granted access.
-- This file is only reached after the empty-schema precondition.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
DO $security$
DECLARE client_role text;
BEGIN
  FOREACH client_role IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=client_role) THEN
      EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA public FROM %I',client_role);
      EXECUTE format('REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM %I',client_role);
      EXECUTE format('REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM %I',client_role);
    END IF;
  END LOOP;
END $security$;
ALTER TABLE public."account_balance_snapshots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."accounts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."cash_flow_event_funding" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."cash_flow_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."cash_flow_rules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."debt_goals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."debt_payment_details" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."finance_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."liabilities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."liability_balance_snapshots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."liability_movements" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."liability_payment_schedule" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."living_budgets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."planned_purchases" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."receipt_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."receipts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."transaction_category_allocations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."transactions" ENABLE ROW LEVEL SECURITY;
