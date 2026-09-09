CREATE INDEX idx_balance_snapshots_account_asof ON public.account_balance_snapshots USING btree (account_id, balance_as_of DESC);

CREATE INDEX idx_balance_snapshots_account_date ON public.account_balance_snapshots USING btree (account_id, balance_date DESC);

CREATE INDEX idx_event_funding_event ON public.cash_flow_event_funding USING btree (cash_flow_event_id);

CREATE INDEX idx_event_funding_transaction ON public.cash_flow_event_funding USING btree (transaction_id);

CREATE INDEX idx_cash_flow_events_account_id ON public.cash_flow_events USING btree (account_id);

CREATE INDEX idx_cash_flow_events_date_status ON public.cash_flow_events USING btree (event_date, status);

CREATE INDEX idx_cash_flow_events_liability_id ON public.cash_flow_events USING btree (liability_id);

CREATE INDEX idx_cash_flow_events_rule_id ON public.cash_flow_events USING btree (rule_id);

CREATE INDEX idx_cash_flow_events_schedule_id ON public.cash_flow_events USING btree (liability_payment_schedule_id);

CREATE INDEX idx_cash_flow_events_source_transaction ON public.cash_flow_events USING btree (source_transaction_id);

CREATE UNIQUE INDEX uq_cash_flow_events_source_key_full ON public.cash_flow_events USING btree (source_key) WHERE (source_key IS NOT NULL);

CREATE INDEX idx_cash_flow_rules_account ON public.cash_flow_rules USING btree (account_id);

CREATE INDEX idx_cash_flow_rules_liability ON public.cash_flow_rules USING btree (liability_id);

CREATE INDEX idx_categories_parent ON public.categories USING btree (parent_id);

CREATE INDEX idx_debt_payment_details_event_id ON public.debt_payment_details USING btree (cash_flow_event_id);

CREATE INDEX idx_debt_payment_details_liability ON public.debt_payment_details USING btree (liability_id);

CREATE INDEX idx_liabilities_linked_account ON public.liabilities USING btree (linked_account_id);

CREATE INDEX idx_liabilities_payment_account ON public.liabilities USING btree (payment_account_id);

CREATE INDEX liabilities_account_idx ON public.liabilities USING btree (account_id);

CREATE UNIQUE INDEX liabilities_revolving_account_unique ON public.liabilities USING btree (linked_account_id) WHERE ((balance_model = 'revolving_account'::text) AND (status = 'active'::text));

CREATE UNIQUE INDEX uq_liabilities_name ON public.liabilities USING btree (name);

CREATE INDEX idx_liability_snapshots_liability_asof ON public.liability_balance_snapshots USING btree (liability_id, balance_as_of DESC);

CREATE INDEX idx_liability_movements_event ON public.liability_movements USING btree (cash_flow_event_id);

CREATE INDEX idx_liability_movements_liability_at ON public.liability_movements USING btree (liability_id, effective_at);

CREATE INDEX liability_movements_detail_idx ON public.liability_movements USING btree (debt_payment_detail_id);

CREATE UNIQUE INDEX uq_liability_movement_tx_type ON public.liability_movements USING btree (transaction_id, movement_type) WHERE (transaction_id IS NOT NULL);

CREATE INDEX idx_planned_purchases_liability ON public.planned_purchases USING btree (liability_id);

CREATE INDEX idx_planned_purchases_status ON public.planned_purchases USING btree (status);

CREATE INDEX idx_planned_purchases_transaction ON public.planned_purchases USING btree (actual_transaction_id);

CREATE INDEX receipt_items_category_idx ON public.receipt_items USING btree (category_id);

CREATE UNIQUE INDEX receipts_fiscal_identity_unique ON public.receipts USING btree (fiscal_drive_number, fiscal_document_number, fiscal_sign) WHERE ((fiscal_drive_number IS NOT NULL) AND (fiscal_document_number IS NOT NULL) AND (fiscal_sign IS NOT NULL));

CREATE INDEX transaction_category_allocations_category_idx ON public.transaction_category_allocations USING btree (category_id);

CREATE INDEX idx_transactions_budget_date ON public.transactions USING btree (budget_effect, transaction_date);

CREATE INDEX idx_transactions_from_occurred ON public.transactions USING btree (from_account_id, occurred_at);

CREATE INDEX idx_transactions_to_occurred ON public.transactions USING btree (to_account_id, occurred_at);

CREATE INDEX transactions_category_idx ON public.transactions USING btree (category_id);

CREATE INDEX transactions_date_idx ON public.transactions USING btree (transaction_date);

CREATE UNIQUE INDEX transactions_external_ref_unique ON public.transactions USING btree (external_ref) WHERE (external_ref IS NOT NULL);

CREATE INDEX transactions_from_account_idx ON public.transactions USING btree (from_account_id);

CREATE INDEX transactions_income_event_idx ON public.transactions USING btree (income_event_id);

CREATE INDEX transactions_liability_idx ON public.transactions USING btree (liability_id);

CREATE INDEX transactions_reserve_liability_idx ON public.transactions USING btree (reserve_liability_id, occurred_at) WHERE (reserve_effect <> 'none'::text);

CREATE INDEX transactions_to_account_idx ON public.transactions USING btree (to_account_id);
