COMMENT ON TABLE public."account_balance_snapshots" IS 'Point-in-time balances of real accounts/payment buffers. Debt principal snapshots live in liability_balance_snapshots.';

COMMENT ON TABLE public."cash_flow_events" IS 'Concrete dated future/actual cash-flow events. Analytical living budget is not a cash-flow event.';

COMMENT ON TABLE public."liability_balance_snapshots" IS 'Point-in-time debt balances; funding a future payment does not change these balances.';

COMMENT ON TABLE public."liability_payment_schedule" IS 'Canonical bank-provided installment schedule. Cash-flow events are materialized from these rows; debt_payment_details stores actual executed decomposition.';

COMMENT ON TABLE public."living_budgets" IS 'Analytical weekly living-budget overrides; not a liability or cash-flow event.';

COMMENT ON TABLE public."planned_purchases" IS 'Analytical reserves for planned major purchases until completed/cancelled/converted to financing.';

COMMENT ON COLUMN public."cash_flow_events"."income_completed_at" IS 'Explicit confirmation that an income is complete even if actual receipts are below plan; NULL means completion is derived from amount.';

COMMENT ON FUNCTION public."correct_finance_transaction"(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb, p_debt_details jsonb, p_event_allocations jsonb, p_receipt_patch jsonb) IS 'Atomic correction. Supply replacement breakdowns when changing amounts; deferred constraints reject incomplete corrections.';

COMMENT ON FUNCTION public."execute_event"(p_event_id bigint, p_from_account_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric) IS 'Canonical command to confirm actual event execution/payment.';

COMMENT ON FUNCTION public."finance_command"(p_request_key text, p_command text, p_args jsonb) IS 'Idempotent entry point for record_transaction, fund_event and execute_event. Reuse request key on retry; different payload with same key is rejected.';

COMMENT ON FUNCTION public."fund_event"(p_event_id bigint, p_from_account_id bigint, p_amount numeric, p_occurred_at timestamp with time zone, p_description text) IS 'Canonical command to secure an event. Creates funding only; never marks the event paid.';

COMMENT ON FUNCTION public."get_credit_cash_reserves"(p_as_of timestamp with time zone, p_horizon_end date) IS 'Reserve actual unrepaid daily card spending and explicitly tagged grace draws, net of scheduled repayments already reserved in the horizon.';

COMMENT ON FUNCTION public."get_financial_position_at"(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric) IS 'Fact at exact cutoff and forecast to target date. Canonical daily status is get_status_until_next_income.';

COMMENT ON FUNCTION public."get_free_cash"(p_as_of timestamp with time zone) IS 'Canonical free cash until next planned income; actual physical cash is get_actual_cash.';

COMMENT ON FUNCTION public."get_liability_balance"(p_liability_id bigint, p_as_of timestamp with time zone) IS 'Legacy card model: principal_balance equals total card debt. For accurate components and availability flag use get_liability_balance_details.';

COMMENT ON FUNCTION public."get_status_until_next_income"(p_as_of timestamp with time zone, p_default_weekly_budget numeric) IS 'Canonical operational finance status. Use this instead of get_financial_position/free_cash for user-facing status.';
