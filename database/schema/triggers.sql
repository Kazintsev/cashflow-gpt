CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.account_balance_snapshots FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER trg_refresh_snapshot_dependents AFTER INSERT OR DELETE OR UPDATE ON public.account_balance_snapshots FOR EACH ROW EXECUTE FUNCTION refresh_snapshot_dependents();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.accounts FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.accounts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.cash_flow_event_funding FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.cash_flow_event_funding DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER trg_apply_event_payment_budget_semantics AFTER INSERT OR UPDATE ON public.cash_flow_event_funding FOR EACH ROW EXECUTE FUNCTION apply_event_payment_budget_semantics();

CREATE TRIGGER trg_refresh_cash_flow_event_from_allocation AFTER INSERT OR DELETE OR UPDATE ON public.cash_flow_event_funding FOR EACH ROW EXECUTE FUNCTION refresh_cash_flow_event_from_allocation();

CREATE TRIGGER trg_validate_cash_flow_allocation BEFORE INSERT OR UPDATE ON public.cash_flow_event_funding FOR EACH ROW EXECUTE FUNCTION validate_cash_flow_allocation();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.cash_flow_events FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.cash_flow_events DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.cash_flow_rules FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER trg_sync_cash_flow_sources AFTER INSERT OR DELETE OR UPDATE ON public.cash_flow_rules FOR EACH STATEMENT EXECUTE FUNCTION sync_cash_flow_sources();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.categories FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.debt_goals FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.debt_payment_details FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.debt_payment_details DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER trg_sync_debt_payment_movements AFTER INSERT OR DELETE OR UPDATE ON public.debt_payment_details FOR EACH ROW EXECUTE FUNCTION sync_debt_payment_movements();

CREATE TRIGGER trg_validate_debt_payment_details BEFORE INSERT OR UPDATE ON public.debt_payment_details FOR EACH ROW EXECUTE FUNCTION validate_debt_payment_details();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.finance_settings FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.liabilities FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.liabilities DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.liability_balance_snapshots FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER trg_refresh_snapshot_dependents AFTER INSERT OR DELETE OR UPDATE ON public.liability_balance_snapshots FOR EACH ROW EXECUTE FUNCTION refresh_snapshot_dependents();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.liability_movements FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.liability_movements DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER trg_sync_liability_cache_from_movements AFTER INSERT OR DELETE OR UPDATE ON public.liability_movements FOR EACH ROW EXECUTE FUNCTION trg_sync_liability_cache_from_movements();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.liability_payment_schedule FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER trg_sync_cash_flow_sources AFTER INSERT OR DELETE OR UPDATE ON public.liability_payment_schedule FOR EACH STATEMENT EXECUTE FUNCTION sync_cash_flow_sources();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.living_budgets FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.planned_purchases FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.receipt_items FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.receipt_items DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.receipts FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.receipts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.transaction_category_allocations FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.transaction_category_allocations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE CONSTRAINT TRIGGER trg_validate_transaction_category_allocations AFTER INSERT OR DELETE OR UPDATE ON public.transaction_category_allocations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_transaction_category_allocations_deferred();

CREATE TRIGGER finance_00_write_lock BEFORE INSERT OR DELETE OR UPDATE ON public.transactions FOR EACH STATEMENT EXECUTE FUNCTION finance_write_lock();

CREATE CONSTRAINT TRIGGER finance_validate_data AFTER INSERT OR DELETE OR UPDATE ON public.transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION finance_validate_data_deferred();

CREATE TRIGGER trg_00_normalize_payment_buffer_funding_semantics BEFORE INSERT OR UPDATE OF transaction_type, from_account_id, to_account_id, budget_effect ON public.transactions FOR EACH ROW EXECUTE FUNCTION normalize_payment_buffer_funding_semantics();

CREATE TRIGGER trg_clear_credit_card_minimum_allocations BEFORE DELETE OR UPDATE OF amount, transaction_date, from_account_id, to_account_id, transaction_type ON public.transactions FOR EACH ROW EXECUTE FUNCTION clear_credit_card_minimum_allocations();

CREATE TRIGGER trg_clear_payment_buffer_funding_allocations BEFORE DELETE OR UPDATE OF amount, transaction_date, occurred_at, from_account_id, to_account_id, transaction_type, liability_id ON public.transactions FOR EACH ROW EXECUTE FUNCTION clear_payment_buffer_funding_allocations();

CREATE TRIGGER trg_credit_card_payment_semantics BEFORE INSERT OR UPDATE OF transaction_type, amount, from_account_id, to_account_id, liability_id, category_id, budget_effect ON public.transactions FOR EACH ROW EXECUTE FUNCTION normalize_credit_card_payment_semantics();

CREATE TRIGGER trg_normalize_transaction_budget_effect BEFORE INSERT OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION normalize_transaction_budget_effect();

CREATE TRIGGER trg_reconcile_credit_card_minimum_from_old_transaction AFTER DELETE OR UPDATE OF amount, transaction_date, occurred_at, from_account_id, to_account_id, transaction_type ON public.transactions FOR EACH ROW EXECUTE FUNCTION reconcile_credit_card_minimum_from_old_transaction();

CREATE TRIGGER trg_reconcile_credit_card_minimum_from_transaction AFTER INSERT OR UPDATE OF amount, transaction_date, occurred_at, from_account_id, to_account_id, transaction_type ON public.transactions FOR EACH ROW EXECUTE FUNCTION reconcile_credit_card_minimum_from_transaction();

CREATE TRIGGER trg_reconcile_payment_buffer_funding_from_transaction AFTER INSERT OR UPDATE OF amount, transaction_date, occurred_at, from_account_id, to_account_id, transaction_type, liability_id ON public.transactions FOR EACH ROW EXECUTE FUNCTION reconcile_payment_buffer_funding_from_transaction();

CREATE TRIGGER trg_refresh_transaction_dependents AFTER UPDATE OF amount, occurred_at, transaction_date, transaction_type, from_account_id, to_account_id, liability_id ON public.transactions FOR EACH ROW EXECUTE FUNCTION refresh_transaction_dependents();

CREATE TRIGGER trg_sync_revolving_liability_cache AFTER INSERT OR DELETE OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION trg_sync_revolving_liability_cache();

CREATE TRIGGER trg_sync_salary_transaction_to_event AFTER INSERT OR DELETE OR UPDATE OF amount, transaction_type, transaction_date, occurred_at, salary_component, salary_period_start, income_event_id ON public.transactions FOR EACH ROW EXECUTE FUNCTION sync_salary_transaction_to_event();

CREATE TRIGGER trg_validate_grace_reserve BEFORE INSERT OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION validate_grace_reserve();

CREATE CONSTRAINT TRIGGER trg_validate_grace_reserve_deferred AFTER INSERT OR DELETE OR UPDATE ON public.transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_grace_reserve_deferred();
