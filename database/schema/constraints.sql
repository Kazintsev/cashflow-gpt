ALTER TABLE public."account_balance_snapshots" ADD CONSTRAINT "account_balance_snapshots_account_time_key" UNIQUE (account_id, balance_as_of);

ALTER TABLE public."account_balance_snapshots" ADD CONSTRAINT "balance_snapshots_pkey" PRIMARY KEY (id);

ALTER TABLE public."accounts" ADD CONSTRAINT "accounts_account_type_check" CHECK ((account_type = ANY (ARRAY['cash'::text, 'bank'::text, 'credit_card'::text, 'loan'::text, 'mortgage'::text, 'savings'::text, 'investment'::text, 'other_asset'::text, 'other_liability'::text, 'payment_buffer'::text])));

ALTER TABLE public."accounts" ADD CONSTRAINT "accounts_pkey" PRIMARY KEY (id);

ALTER TABLE public."accounts" ADD CONSTRAINT "accounts_rub" CHECK ((currency = 'RUB'::text));

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_allocation_source_check" CHECK ((allocation_source = ANY (ARRAY['manual'::text, 'auto_card_minimum'::text, 'auto_installment'::text, 'auto_payment_buffer'::text])));

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_amount_check" CHECK ((amount > (0)::numeric));

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_cash_flow_event_id_transaction_id_key" UNIQUE (cash_flow_event_id, transaction_id);

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_pkey" PRIMARY KEY (id);

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_relation_type_check" CHECK ((relation_type = ANY (ARRAY['funding'::text, 'payment'::text])));

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_fulfillment_mode_check" CHECK ((fulfillment_mode = ANY (ARRAY['dated_payment'::text, 'cumulative_contributions'::text])));

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_pkey" PRIMARY KEY (id);

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_source_type_check" CHECK ((source_type = ANY (ARRAY['manual'::text, 'rule'::text, 'split_schedule'::text, 'legacy'::text, 'bank_schedule'::text, 'card_minimum'::text])));

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_status_check" CHECK ((status = ANY (ARRAY['planned'::text, 'partially_secured'::text, 'secured'::text, 'partially_executed'::text, 'executed'::text, 'cancelled'::text])));

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_valid_amount" CHECK (((amount >= (0)::numeric) AND (amount <> ALL (ARRAY['NaN'::numeric, 'Infinity'::numeric, '-Infinity'::numeric]))));

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_valid_type" CHECK ((event_type = ANY (ARRAY['income'::text, 'expense'::text, 'debt_payment'::text, 'planned_expense'::text])));

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_event_type_check" CHECK (((event_type IS NULL) OR (event_type = ANY (ARRAY['income'::text, 'expense'::text, 'debt_payment'::text]))));

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_name_key" UNIQUE (name);

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_pkey" PRIMARY KEY (id);

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_rub" CHECK ((currency = 'RUB'::text));

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_rule_type_check" CHECK ((rule_type = ANY (ARRAY['fixed'::text, 'salary_advance'::text, 'salary_balance'::text, 'recurring_obligation'::text, 'salary'::text, 'living_budget'::text])));

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_schedule_type_check" CHECK ((schedule_type = ANY (ARRAY['monthly'::text, 'weekly'::text])));

ALTER TABLE public."categories" ADD CONSTRAINT "categories_category_type_check" CHECK ((category_type = ANY (ARRAY['income'::text, 'expense'::text, 'transfer'::text, 'debt'::text, 'fee'::text])));

ALTER TABLE public."categories" ADD CONSTRAINT "categories_name_category_type_key" UNIQUE (name, category_type);

ALTER TABLE public."categories" ADD CONSTRAINT "categories_pkey" PRIMARY KEY (id);

ALTER TABLE public."debt_goals" ADD CONSTRAINT "debt_goals_liability_id_key" UNIQUE (liability_id);

ALTER TABLE public."debt_goals" ADD CONSTRAINT "debt_goals_pkey" PRIMARY KEY (id);

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_check" CHECK ((((principal_amount + interest_amount) + fee_amount) > (0)::numeric));

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_fee_amount_check" CHECK ((fee_amount >= (0)::numeric));

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_interest_amount_check" CHECK ((interest_amount >= (0)::numeric));

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_pkey" PRIMARY KEY (id);

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_principal_amount_check" CHECK ((principal_amount >= (0)::numeric));

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_transaction_id_key" UNIQUE (transaction_id);

ALTER TABLE public."finance_settings" ADD CONSTRAINT "finance_settings_pkey" PRIMARY KEY (key);

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_balance_model_check" CHECK (((balance_model IS NULL) OR (balance_model = ANY (ARRAY['revolving_account'::text, 'installment'::text]))));

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_liability_type_check" CHECK ((liability_type = ANY (ARRAY['credit_card'::text, 'consumer_loan'::text, 'mortgage'::text, 'other_loan'::text])));

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_minimum_payment_calculation_day_check" CHECK (((minimum_payment_calculation_day IS NULL) OR ((minimum_payment_calculation_day >= 1) AND (minimum_payment_calculation_day <= 31))));

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_model_accounts" CHECK ((((balance_model = 'installment'::text) AND (payment_account_id IS NOT NULL) AND (linked_account_id IS NULL)) OR ((balance_model = 'revolving_account'::text) AND (linked_account_id IS NOT NULL))));

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_payment_day_check" CHECK (((payment_day >= 1) AND (payment_day <= 31)));

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_pkey" PRIMARY KEY (id);

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'closed'::text, 'paused'::text])));

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_accrued_interest_check" CHECK ((accrued_interest >= (0)::numeric));

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_fees_due_check" CHECK ((fees_due >= (0)::numeric));

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_liability_id_balance_as_of_key" UNIQUE (liability_id, balance_as_of);

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_pkey" PRIMARY KEY (id);

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_principal_balance_check" CHECK ((principal_balance >= (0)::numeric));

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_amount_check" CHECK ((amount > (0)::numeric));

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_direction_check" CHECK ((direction = ANY (ARRAY['-1'::integer, 1])));

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_movement_type_check" CHECK ((movement_type = ANY (ARRAY['principal_increase'::text, 'principal_payment'::text, 'interest_accrual'::text, 'interest_payment'::text, 'fee_accrual'::text, 'fee_payment'::text, 'principal_adjustment'::text, 'interest_adjustment'::text, 'fee_adjustment'::text])));

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_pkey" PRIMARY KEY (id);

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_components_check" CHECK ((round(((principal_amount + interest_amount) + fee_amount), 2) = round(total_amount, 2)));

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_fee_amount_check" CHECK ((fee_amount >= (0)::numeric));

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_interest_amount_check" CHECK ((interest_amount >= (0)::numeric));

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_liability_date_key" UNIQUE (liability_id, payment_date);

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_pkey" PRIMARY KEY (id);

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_principal_amount_check" CHECK ((principal_amount >= (0)::numeric));

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_principal_before_check" CHECK ((principal_before >= (0)::numeric));

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_total_amount_check" CHECK ((total_amount >= (0)::numeric));

ALTER TABLE public."living_budgets" ADD CONSTRAINT "living_budgets_amount_check" CHECK ((amount >= (0)::numeric));

ALTER TABLE public."living_budgets" ADD CONSTRAINT "living_budgets_monday" CHECK ((EXTRACT(isodow FROM week_start) = (1)::numeric));

ALTER TABLE public."living_budgets" ADD CONSTRAINT "living_budgets_pkey" PRIMARY KEY (id);

ALTER TABLE public."living_budgets" ADD CONSTRAINT "living_budgets_week_start_key" UNIQUE (week_start);

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_financing_method_check" CHECK (((financing_method IS NULL) OR (financing_method = ANY (ARRAY['cash'::text, 'credit_card'::text, 'split'::text, 'other_credit'::text, 'unknown'::text]))));

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_pkey" PRIMARY KEY (id);

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_planned_amount_check" CHECK ((planned_amount > (0)::numeric));

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'cancelled'::text, 'converted_to_split'::text, 'converted_to_credit'::text])));

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_amount_check" CHECK ((amount > (0)::numeric));

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_confidence_check" CHECK (((confidence IS NULL) OR ((confidence >= (0)::numeric) AND (confidence <= (1)::numeric))));

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_nonnegative_price" CHECK (((unit_price IS NULL) OR (unit_price >= (0)::numeric)));

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_pkey" PRIMARY KEY (id);

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_positive_quantity" CHECK (((quantity IS NULL) OR (quantity > (0)::numeric)));

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_receipt_id_line_number_key" UNIQUE (receipt_id, line_number);

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_parse_status_check" CHECK ((parse_status = ANY (ARRAY['category_only'::text, 'items_parsed'::text, 'verified_online'::text])));

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_pkey" PRIMARY KEY (id);

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_source_check" CHECK ((source = ANY (ARRAY['photo'::text, 'fns'::text, 'manual'::text])));

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_total_amount_check" CHECK ((total_amount > (0)::numeric));

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_transaction_id_key" UNIQUE (transaction_id);

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_allocation_source_check" CHECK ((allocation_source = ANY (ARRAY['manual'::text, 'receipt'::text, 'rule'::text, 'import'::text])));

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_amount_check" CHECK ((amount > (0)::numeric));

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_pkey" PRIMARY KEY (id);

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_transaction_id_category_id_key" UNIQUE (transaction_id, category_id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_amount_check" CHECK ((amount > (0)::numeric));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_budget_effect_check" CHECK ((budget_effect = ANY (ARRAY['life'::text, 'excluded'::text, 'none'::text])));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_check" CHECK ((((transaction_type = 'expense'::text) AND (from_account_id IS NOT NULL) AND (to_account_id IS NULL)) OR ((transaction_type = 'income'::text) AND (from_account_id IS NULL) AND (to_account_id IS NOT NULL)) OR ((transaction_type = 'transfer'::text) AND (from_account_id IS NOT NULL) AND (to_account_id IS NOT NULL) AND (from_account_id <> to_account_id)) OR (transaction_type = ANY (ARRAY['debt_payment'::text, 'interest'::text, 'fee'::text, 'adjustment'::text]))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_debit_sides" CHECK (((transaction_type <> ALL (ARRAY['debt_payment'::text, 'interest'::text, 'fee'::text])) OR ((from_account_id IS NOT NULL) AND ((transaction_type = 'debt_payment'::text) OR (to_account_id IS NULL)))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_finite_amount" CHECK ((amount <> 'NaN'::numeric));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_income_metadata" CHECK (((transaction_type = 'income'::text) OR ((income_event_id IS NULL) AND (salary_component IS NULL) AND (salary_period_start IS NULL))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_life_only_for_expenses" CHECK (((budget_effect <> 'life'::text) OR (transaction_type = 'expense'::text)));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_nonempty_sides" CHECK ((((from_account_id IS NOT NULL) OR (to_account_id IS NOT NULL)) AND ((from_account_id IS NULL) OR (to_account_id IS NULL) OR (from_account_id <> to_account_id))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_pkey" PRIMARY KEY (id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_reserve_effect_check" CHECK ((reserve_effect = ANY (ARRAY['none'::text, 'grace_draw'::text, 'grace_repay'::text])));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_reserve_metadata" CHECK ((((reserve_effect = 'none'::text) AND (reserve_cycle IS NULL) AND (reserve_due_date IS NULL) AND (reserve_liability_id IS NULL)) OR ((reserve_effect <> 'none'::text) AND (NULLIF(btrim(reserve_cycle), ''::text) IS NOT NULL) AND (reserve_due_date IS NOT NULL) AND (reserve_liability_id IS NOT NULL))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_rub" CHECK ((currency = 'RUB'::text));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_salary_component_check" CHECK (((salary_component IS NULL) OR (salary_component = ANY (ARRAY['advance'::text, 'salary'::text, 'vacation'::text, 'bonus'::text, 'other'::text]))));

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_transaction_type_check" CHECK ((transaction_type = ANY (ARRAY['expense'::text, 'income'::text, 'transfer'::text, 'debt_payment'::text, 'interest'::text, 'fee'::text, 'adjustment'::text])));

ALTER TABLE public."account_balance_snapshots" ADD CONSTRAINT "balance_snapshots_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_cash_flow_event_id_fkey" FOREIGN KEY (cash_flow_event_id) REFERENCES cash_flow_events(id) ON DELETE CASCADE;

ALTER TABLE public."cash_flow_event_funding" ADD CONSTRAINT "cash_flow_event_funding_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id);

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id);

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_liability_payment_schedule_id_fkey" FOREIGN KEY (liability_payment_schedule_id) REFERENCES liability_payment_schedule(id) ON DELETE SET NULL;

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_rule_id_fkey" FOREIGN KEY (rule_id) REFERENCES cash_flow_rules(id);

ALTER TABLE public."cash_flow_events" ADD CONSTRAINT "cash_flow_events_source_transaction_id_fkey" FOREIGN KEY (source_transaction_id) REFERENCES transactions(id) ON DELETE SET NULL;

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL;

ALTER TABLE public."cash_flow_rules" ADD CONSTRAINT "cash_flow_rules_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE SET NULL;

ALTER TABLE public."categories" ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES categories(id);

ALTER TABLE public."debt_goals" ADD CONSTRAINT "debt_goals_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE CASCADE;

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_cash_flow_event_id_fkey" FOREIGN KEY (cash_flow_event_id) REFERENCES cash_flow_events(id);

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE CASCADE;

ALTER TABLE public."debt_payment_details" ADD CONSTRAINT "debt_payment_details_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_linked_account_id_fkey" FOREIGN KEY (linked_account_id) REFERENCES accounts(id);

ALTER TABLE public."liabilities" ADD CONSTRAINT "liabilities_payment_account_id_fkey" FOREIGN KEY (payment_account_id) REFERENCES accounts(id);

ALTER TABLE public."liability_balance_snapshots" ADD CONSTRAINT "liability_balance_snapshots_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE CASCADE;

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_cash_flow_event_id_fkey" FOREIGN KEY (cash_flow_event_id) REFERENCES cash_flow_events(id) ON DELETE SET NULL;

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_debt_payment_detail_id_fkey" FOREIGN KEY (debt_payment_detail_id) REFERENCES debt_payment_details(id) ON DELETE CASCADE;

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE CASCADE;

ALTER TABLE public."liability_movements" ADD CONSTRAINT "liability_movements_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;

ALTER TABLE public."liability_payment_schedule" ADD CONSTRAINT "liability_payment_schedule_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id);

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_actual_transaction_id_fkey" FOREIGN KEY (actual_transaction_id) REFERENCES transactions(id) ON DELETE SET NULL;

ALTER TABLE public."planned_purchases" ADD CONSTRAINT "planned_purchases_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id) ON DELETE SET NULL;

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_category_id_fkey" FOREIGN KEY (category_id) REFERENCES categories(id);

ALTER TABLE public."receipt_items" ADD CONSTRAINT "receipt_items_receipt_id_fkey" FOREIGN KEY (receipt_id) REFERENCES receipts(id) ON DELETE CASCADE;

ALTER TABLE public."receipts" ADD CONSTRAINT "receipts_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_category_id_fkey" FOREIGN KEY (category_id) REFERENCES categories(id);

ALTER TABLE public."transaction_category_allocations" ADD CONSTRAINT "transaction_category_allocations_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_category_id_fkey" FOREIGN KEY (category_id) REFERENCES categories(id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_from_account_id_fkey" FOREIGN KEY (from_account_id) REFERENCES accounts(id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_income_event_id_fkey" FOREIGN KEY (income_event_id) REFERENCES cash_flow_events(id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_liability_id_fkey" FOREIGN KEY (liability_id) REFERENCES liabilities(id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_reserve_liability_id_fkey" FOREIGN KEY (reserve_liability_id) REFERENCES liabilities(id);

ALTER TABLE public."transactions" ADD CONSTRAINT "transactions_to_account_id_fkey" FOREIGN KEY (to_account_id) REFERENCES accounts(id);
