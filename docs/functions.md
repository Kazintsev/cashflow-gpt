# Каталог функций

> ID: function_reference · Для: developer, agent · Тип: observed_snapshot
>
> Точные сигнатуры и отдельные якоря перегрузок. [Карта документации](index.md) · [Манифест](manifest.json)

В каталоге 76 сигнатур схемы `public`, включая перегрузки и триггерные функции. Сигнатуры и возвращаемые типы получены из PostgreSQL 8 сентября 2026 года. Это инвентаризация, а не обещание стабильности всех внутренних вызовов. Для интеграции начинайте с [прикладного API](api.md).

В сигнатурах ниже значения DEFAULT намеренно опущены; параметры с defaults перечислены отдельно. Для фактического вызова используйте именованные аргументы и явные типы. Полные тела с DEFAULT доступны по ссылке «Исходник SQL» у каждой сигнатуры. [Структура и отличия экспорта](source-code.md).

Все обследованные функции исполняются с правами вызывающего (`SECURITY INVOKER`). Метка `VOLATILE` сама по себе не доказывает изменение данных; для административных и триггерных функций необходимо читать реализацию.

## Навигация

| Функция | Возвращает | Volatility |
|---|---|---|
| [`apply_event_payment_budget_semantics()`](#fn-apply-event-payment-budget-semantics-12658278ea) | `trigger` | VOLATILE |
| [`assert_free_cash_invariant(p_before numeric, p_after numeric, p_context text, p_tolerance numeric)`](#fn-assert-free-cash-invariant-a2c2858b89) | `void` | IMMUTABLE |
| [`business_day_on_or_before(d date)`](#fn-business-day-on-or-before-cebbf35516) | `date` | IMMUTABLE |
| [`clear_credit_card_minimum_allocations()`](#fn-clear-credit-card-minimum-allocations-a521adf21e) | `trigger` | VOLATILE |
| [`clear_payment_buffer_funding_allocations()`](#fn-clear-payment-buffer-funding-allocations-765bde8b76) | `trigger` | VOLATILE |
| [`complete_income_event(p_event_id bigint, p_completed_at timestamp with time zone)`](#fn-complete-income-event-935dedcc55) | `void` | VOLATILE |
| [`correct_finance_transaction(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb, p_debt_details jsonb, p_event_allocations jsonb, p_receipt_patch jsonb)`](#fn-correct-finance-transaction-9009324eb2) | `transactions` | VOLATILE |
| [`execute_event(p_event_id bigint, p_from_account_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)`](#fn-execute-event-5dc04a140f) | `bigint` | VOLATILE |
| [`execute_installment_payment(p_event_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)`](#fn-execute-installment-payment-84817fc831) | `bigint` | VOLATILE |
| [`finance_business_date(p_ts timestamp with time zone)`](#fn-finance-business-date-425398addf) | `date` | STABLE |
| [`finance_command(p_request_key text, p_command text, p_args jsonb)`](#fn-finance-command-4c19d2b97f) | `bigint` | VOLATILE |
| [`finance_data_issues()`](#fn-finance-data-issues-5926da9222) | `TABLE(code text, entity_id bigint, details jsonb)` | STABLE |
| [`finance_day_end(p_date date)`](#fn-finance-day-end-c0ec7af4f3) | `timestamp with time zone` | STABLE |
| [`finance_day_start(p_date date)`](#fn-finance-day-start-04625df52f) | `timestamp with time zone` | STABLE |
| [`finance_integrity_check(p_as_of timestamp with time zone)`](#fn-finance-integrity-check-b9b78cef5e) | `TABLE(severity text, code text, entity_type text, entity_id bigint, message text, details jsonb)` | STABLE |
| [`finance_setting_numeric(p_key text, p_default numeric)`](#fn-finance-setting-numeric-7c24e5a300) | `numeric` | STABLE |
| [`finance_setting_text(p_key text, p_default text)`](#fn-finance-setting-text-5e1df66f14) | `text` | STABLE |
| [`finance_validate_data_deferred()`](#fn-finance-validate-data-deferred-9903e2cc8c) | `trigger` | VOLATILE |
| [`finance_write_lock()`](#fn-finance-write-lock-493e7475cb) | `trigger` | VOLATILE |
| [`forecast_free_cash(p_target_date date, p_weekly_living numeric, p_reserve numeric)`](#fn-forecast-free-cash-888649f7ff) | `TABLE(current_free_cash numeric, planned_income numeric, secured_outflows numeric, unsecure_outflows numeric, remaining_living_budget numeric, living_budget_overrun numeric, future_living_budget numeric, projected_free_cash numeric, safe_extra_payment numeric)` | STABLE |
| [`fund_event(p_event_id bigint, p_from_account_id bigint, p_amount numeric, p_occurred_at timestamp with time zone, p_description text)`](#fn-fund-event-e24cde05db) | `bigint` | VOLATILE |
| [`generate_cash_flow_events(from_date date, to_date date)`](#fn-generate-cash-flow-events-5188dc9aeb) | `void` | VOLATILE |
| [`get_account_balance(p_account_id bigint, p_as_of date)`](#fn-get-account-balance-329abeba8c) | `numeric` | STABLE |
| [`get_account_balance(p_account_id bigint, p_as_of timestamp with time zone)`](#fn-get-account-balance-654dfdbb2e) | `numeric` | STABLE |
| [`get_actual_cash(p_as_of date)`](#fn-get-actual-cash-4d54a90000) | `numeric` | STABLE |
| [`get_actual_cash(p_as_of timestamp with time zone)`](#fn-get-actual-cash-f161cecaef) | `numeric` | STABLE |
| [`get_cash_flow_event_coverage(p_event_id bigint)`](#fn-get-cash-flow-event-coverage-af94ef53c9) | `TABLE(planned_amount numeric, paid_amount numeric, funded_amount numeric, remaining_payment_amount numeric, remaining_funding_amount numeric)` | STABLE |
| [`get_cash_flow_event_state_as_of(p_as_of timestamp with time zone)`](#fn-get-cash-flow-event-state-as-of-e6aad22f44) | `TABLE(event_id bigint, event_date date, event_type text, amount numeric, description text, account_id bigint, liability_id bigint, status text, paid_amount numeric, funded_amount numeric, cash_committed_amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)` | STABLE |
| [`get_credit_budget_position(p_as_of timestamp with time zone)`](#fn-get-credit-budget-position-a68ed80ef8) | `TABLE(account_id bigint, account_name text, life_spend_total numeric, cash_repayments_total numeric, unsettled_budget_spend numeric, this_week_life_spend numeric, this_week_cash_repayments numeric, this_week_unsettled numeric, carryover_unsettled numeric, strategic_repayments numeric)` | STABLE |
| [`get_credit_cash_reserves(p_as_of timestamp with time zone, p_horizon_end date)`](#fn-get-credit-cash-reserves-48133ca082) | `TABLE(account_id bigint, unpaid_life numeric, grace_outstanding numeric, scheduled_repayments numeric, additional_reserve numeric)` | STABLE |
| [`get_expense_category_lines(p_start date, p_end date)`](#fn-get-expense-category-lines-25428b0831) | `TABLE(transaction_id bigint, transaction_date date, description text, category_id bigint, category_name text, amount numeric, allocation_source text)` | STABLE |
| [`get_financial_position(p_as_of date, p_default_weekly_budget numeric)`](#fn-get-financial-position-d043b30aa9) | `TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)` | STABLE |
| [`get_financial_position(p_as_of timestamp with time zone, p_default_weekly_budget numeric)`](#fn-get-financial-position-6ee5ec6561) | `TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)` | STABLE |
| [`get_financial_position_at(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric)`](#fn-get-financial-position-at-9f14d7d31e) | `TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)` | STABLE |
| [`get_financial_position_v2(p_as_of date, p_default_weekly_budget numeric)`](#fn-get-financial-position-v2-588bed1dca) | `TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)` | STABLE |
| [`get_free_cash(p_as_of date)`](#fn-get-free-cash-5de924fe5e) | `numeric` | STABLE |
| [`get_free_cash(p_as_of timestamp with time zone)`](#fn-get-free-cash-5ed941717d) | `numeric` | STABLE |
| [`get_income_event_state_as_of(p_as_of timestamp with time zone)`](#fn-get-income-event-state-as-of-e07cdd98ff) | `TABLE(event_id bigint, received_amount numeric, remaining_amount numeric, derived_status text, last_received_at timestamp with time zone)` | STABLE |
| [`get_liability_balance(p_liability_id bigint, p_as_of date)`](#fn-get-liability-balance-4540d0944f) | `TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)` | STABLE |
| [`get_liability_balance(p_liability_id bigint, p_as_of timestamp with time zone)`](#fn-get-liability-balance-8d1c73d395) | `TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)` | STABLE |
| [`get_liability_balance_details(p_liability_id bigint, p_as_of timestamp with time zone)`](#fn-get-liability-balance-details-0017571ee7) | `TABLE(total_debt numeric, principal_balance numeric, accrued_interest numeric, fees_due numeric, components_known boolean, components_as_of timestamp with time zone)` | STABLE |
| [`get_liquidity_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)`](#fn-get-liquidity-until-next-income-5a43c09635) | `TABLE(as_of timestamp with time zone, business_date date, next_income_date date, next_income_description text, next_income_amount numeric, actual_cash numeric, required_outflows_before_income numeric, remaining_living_budget numeric, future_living_budget numeric, planned_purchase_reserve numeric, free_cash_until_next_income numeric)` | STABLE |
| [`get_living_budget_reserve(p_week_start date, p_as_of timestamp with time zone, p_default_budget numeric)`](#fn-get-living-budget-reserve-e27d063804) | `TABLE(budget_amount numeric, spent_amount numeric, earmarked_amount numeric, remaining_reserve numeric, overrun numeric)` | STABLE |
| [`get_obligations_until_next_income(p_as_of timestamp with time zone)`](#fn-get-obligations-until-next-income-67aba6d215) | `TABLE(next_income_date date, event_id bigint, event_date date, description text, amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)` | STABLE |
| [`get_settlement_attention(p_as_of date)`](#fn-get-settlement-attention-8b310d39ab) | `TABLE(event_id bigint, event_date date, description text, amount numeric, paid_amount numeric, funded_amount numeric, cash_still_required numeric, remaining_payment_amount numeric, derived_status text, timing_status text, attention_status text)` | STABLE |
| [`get_status_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)`](#fn-get-status-until-next-income-8d89e6dc13) | `jsonb` | STABLE |
| [`get_upcoming_payments(p_days integer)`](#fn-get-upcoming-payments-cf8a6c80ca) | `TABLE(event_id bigint, event_date date, description text, amount numeric, secured boolean, security_transaction_id bigint, security_note text)` | STABLE |
| [`link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric)`](#fn-link-funding-183bf77d8a) | `void` | VOLATILE |
| [`link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric, p_relation_type text)`](#fn-link-funding-baaab7d6e0) | `void` | VOLATILE |
| [`normalize_credit_card_payment_semantics()`](#fn-normalize-credit-card-payment-semantics-4d193efffb) | `trigger` | VOLATILE |
| [`normalize_payment_buffer_funding_semantics()`](#fn-normalize-payment-buffer-funding-semantics-16ab0a0576) | `trigger` | VOLATILE |
| [`normalize_transaction_budget_effect()`](#fn-normalize-transaction-budget-effect-9e6add9034) | `trigger` | VOLATILE |
| [`rebuild_debt_payment_movements(p_liability_id bigint)`](#fn-rebuild-debt-payment-movements-cadf8bb48d) | `void` | VOLATILE |
| [`reconcile_credit_card_minimum(p_event_id bigint)`](#fn-reconcile-credit-card-minimum-ea61b8cf4b) | `void` | VOLATILE |
| [`reconcile_credit_card_minimum_from_old_transaction()`](#fn-reconcile-credit-card-minimum-from-old-transaction-4945a36f7d) | `trigger` | VOLATILE |
| [`reconcile_credit_card_minimum_from_transaction()`](#fn-reconcile-credit-card-minimum-from-transaction-189bfba7de) | `trigger` | VOLATILE |
| [`reconcile_payment_buffer_funding_from_transaction()`](#fn-reconcile-payment-buffer-funding-from-transaction-2d2145772a) | `trigger` | VOLATILE |
| [`refresh_cash_flow()`](#fn-refresh-cash-flow-24981a6d0a) | `void` | VOLATILE |
| [`refresh_cash_flow_event_from_allocation()`](#fn-refresh-cash-flow-event-from-allocation-176c3ff941) | `trigger` | VOLATILE |
| [`refresh_cash_flow_event_status(p_event_id bigint)`](#fn-refresh-cash-flow-event-status-7a84b59058) | `cash_flow_events` | VOLATILE |
| [`refresh_cash_flow_security(p_start date, p_end date)`](#fn-refresh-cash-flow-security-bef82af046) | `integer` | VOLATILE |
| [`refresh_event_security()`](#fn-refresh-event-security-cb28073649) | `void` | VOLATILE |
| [`refresh_snapshot_dependents()`](#fn-refresh-snapshot-dependents-e774891266) | `trigger` | VOLATILE |
| [`refresh_transaction_dependents()`](#fn-refresh-transaction-dependents-3513c6b0a2) | `trigger` | VOLATILE |
| [`set_credit_card_minimum(p_liability_id bigint, p_amount numeric, p_due_date date)`](#fn-set-credit-card-minimum-613f21d5d7) | `bigint` | VOLATILE |
| [`sync_cash_flow_sources()`](#fn-sync-cash-flow-sources-2ed9ef51b8) | `trigger` | VOLATILE |
| [`sync_debt_payment_movements()`](#fn-sync-debt-payment-movements-e4b6004cb5) | `trigger` | VOLATILE |
| [`sync_liability_principal_cache(p_liability_id bigint)`](#fn-sync-liability-principal-cache-493f3f0c4a) | `void` | VOLATILE |
| [`sync_salary_transaction_to_event()`](#fn-sync-salary-transaction-to-event-845fb072a1) | `trigger` | VOLATILE |
| [`trg_sync_liability_cache_from_movements()`](#fn-trg-sync-liability-cache-from-movements-68942a8473) | `trigger` | VOLATILE |
| [`trg_sync_revolving_liability_cache()`](#fn-trg-sync-revolving-liability-cache-da3ad9487b) | `trigger` | VOLATILE |
| [`validate_cash_flow_allocation()`](#fn-validate-cash-flow-allocation-7bc13b6030) | `trigger` | VOLATILE |
| [`validate_debt_payment_details()`](#fn-validate-debt-payment-details-fc68f8438d) | `trigger` | VOLATILE |
| [`validate_grace_reserve()`](#fn-validate-grace-reserve-d63891a4f9) | `trigger` | VOLATILE |
| [`validate_grace_reserve_deferred()`](#fn-validate-grace-reserve-deferred-303d13b645) | `trigger` | VOLATILE |
| [`validate_transaction_category_allocations_deferred()`](#fn-validate-transaction-category-allocations-deferred-2a4024676f) | `trigger` | VOLATILE |

<a id="fn-apply-event-payment-budget-semantics-12658278ea"></a>

[Исходник SQL](../database/functions/apply_event_payment_budget_semantics--12658278ea.sql)

## apply_event_payment_budget_semantics

```sql
public.apply_event_payment_budget_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-assert-free-cash-invariant-a2c2858b89"></a>

[Исходник SQL](../database/functions/assert_free_cash_invariant--a2c2858b89.sql)

## assert_free_cash_invariant

```sql
public.assert_free_cash_invariant(p_before numeric, p_after numeric, p_context text, p_tolerance numeric)
RETURNS void
```

Параметры со значениями по умолчанию: `p_tolerance`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-business-day-on-or-before-cebbf35516"></a>

[Исходник SQL](../database/functions/business_day_on_or_before--cebbf35516.sql)

## business_day_on_or_before

```sql
public.business_day_on_or_before(d date)
RETURNS date
```

Параметры со значениями по умолчанию: нет.

Перенос только субботы/воскресенья на пятницу; без праздничного календаря.


<a id="fn-clear-credit-card-minimum-allocations-a521adf21e"></a>

[Исходник SQL](../database/functions/clear_credit_card_minimum_allocations--a521adf21e.sql)

## clear_credit_card_minimum_allocations

```sql
public.clear_credit_card_minimum_allocations()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-clear-payment-buffer-funding-allocations-765bde8b76"></a>

[Исходник SQL](../database/functions/clear_payment_buffer_funding_allocations--765bde8b76.sql)

## clear_payment_buffer_funding_allocations

```sql
public.clear_payment_buffer_funding_allocations()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-complete-income-event-935dedcc55"></a>

[Исходник SQL](../database/functions/complete_income_event--935dedcc55.sql)

## complete_income_event

```sql
public.complete_income_event(p_event_id bigint, p_completed_at timestamp with time zone)
RETURNS void
```

Параметры со значениями по умолчанию: `p_completed_at`.

Подтверждение завершения дохода после хотя бы одного зачисления.


<a id="fn-correct-finance-transaction-9009324eb2"></a>

[Исходник SQL](../database/functions/correct_finance_transaction--9009324eb2.sql)

## correct_finance_transaction

```sql
public.correct_finance_transaction(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb, p_debt_details jsonb, p_event_allocations jsonb, p_receipt_patch jsonb)
RETURNS transactions
```

Параметры со значениями по умолчанию: `p_category_allocations`, `p_debt_details`, `p_event_allocations`, `p_receipt_patch`.

Атомарное исправление операции и переданных зависимых разбиений.

Комментарий в БД: Atomic correction. Supply replacement breakdowns when changing amounts; deferred constraints reject incomplete corrections.


<a id="fn-execute-event-5dc04a140f"></a>

[Исходник SQL](../database/functions/execute_event--5dc04a140f.sql)

## execute_event

```sql
public.execute_event(p_event_id bigint, p_from_account_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_from_account_id`, `p_occurred_at`, `p_actual_amount`, `p_principal_amount`, `p_interest_amount`, `p_fee_amount`.

Фактическое исполнение расходного события.

Комментарий в БД: Canonical command to confirm actual event execution/payment.


<a id="fn-execute-installment-payment-84817fc831"></a>

[Исходник SQL](../database/functions/execute_installment_payment--84817fc831.sql)

## execute_installment_payment

```sql
public.execute_installment_payment(p_event_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_occurred_at`, `p_actual_amount`, `p_principal_amount`, `p_interest_amount`, `p_fee_amount`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-finance-business-date-425398addf"></a>

[Исходник SQL](../database/functions/finance_business_date--425398addf.sql)

## finance_business_date

```sql
public.finance_business_date(p_ts timestamp with time zone)
RETURNS date
```

Параметры со значениями по умолчанию: `p_ts`.

Бизнес-дата момента времени.


<a id="fn-finance-command-4c19d2b97f"></a>

[Исходник SQL](../database/functions/finance_command--4c19d2b97f.sql)

## finance_command

```sql
public.finance_command(p_request_key text, p_command text, p_args jsonb)
RETURNS bigint
```

Параметры со значениями по умолчанию: нет.

Предпочтительная обёртка записи с ключом повторного запроса. См. прикладной API.

Комментарий в БД: Idempotent entry point for record_transaction, fund_event and execute_event. Reuse request key on retry; different payload with same key is rejected.


<a id="fn-finance-data-issues-5926da9222"></a>

[Исходник SQL](../database/functions/finance_data_issues--5926da9222.sql)

## finance_data_issues

```sql
public.finance_data_issues()
RETURNS TABLE(code text, entity_id bigint, details jsonb)
```

Параметры со значениями по умолчанию: нет.

Структурные/семантические проблемы текущих данных.


<a id="fn-finance-day-end-c0ec7af4f3"></a>

[Исходник SQL](../database/functions/finance_day_end--c0ec7af4f3.sql)

## finance_day_end

```sql
public.finance_day_end(p_date date)
RETURNS timestamp with time zone
```

Параметры со значениями по умолчанию: нет.

Конец дня в business_timezone с точностью до микросекунды.


<a id="fn-finance-day-start-04625df52f"></a>

[Исходник SQL](../database/functions/finance_day_start--04625df52f.sql)

## finance_day_start

```sql
public.finance_day_start(p_date date)
RETURNS timestamp with time zone
```

Параметры со значениями по умолчанию: нет.

Начало дня в business_timezone.


<a id="fn-finance-integrity-check-b9b78cef5e"></a>

[Исходник SQL](../database/functions/finance_integrity_check--b9b78cef5e.sql)

## finance_integrity_check

```sql
public.finance_integrity_check(p_as_of timestamp with time zone)
RETURNS TABLE(severity text, code text, entity_type text, entity_id bigint, message text, details jsonb)
```

Параметры со значениями по умолчанию: `p_as_of`.

Диагностика согласованности с severity, code и details.


<a id="fn-finance-setting-numeric-7c24e5a300"></a>

[Исходник SQL](../database/functions/finance_setting_numeric--7c24e5a300.sql)

## finance_setting_numeric

```sql
public.finance_setting_numeric(p_key text, p_default numeric)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_default`.

Числовая настройка JSONB с fallback.


<a id="fn-finance-setting-text-5e1df66f14"></a>

[Исходник SQL](../database/functions/finance_setting_text--5e1df66f14.sql)

## finance_setting_text

```sql
public.finance_setting_text(p_key text, p_default text)
RETURNS text
```

Параметры со значениями по умолчанию: `p_default`.

Текстовая настройка JSONB с fallback.


<a id="fn-finance-validate-data-deferred-9903e2cc8c"></a>

[Исходник SQL](../database/functions/finance_validate_data_deferred--9903e2cc8c.sql)

## finance_validate_data_deferred

```sql
public.finance_validate_data_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-finance-write-lock-493e7475cb"></a>

[Исходник SQL](../database/functions/finance_write_lock--493e7475cb.sql)

## finance_write_lock

```sql
public.finance_write_lock()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-forecast-free-cash-888649f7ff"></a>

[Исходник SQL](../database/functions/forecast_free_cash--888649f7ff.sql)

## forecast_free_cash

```sql
public.forecast_free_cash(p_target_date date, p_weekly_living numeric, p_reserve numeric)
RETURNS TABLE(current_free_cash numeric, planned_income numeric, secured_outflows numeric, unsecure_outflows numeric, remaining_living_budget numeric, living_budget_overrun numeric, future_living_budget numeric, projected_free_cash numeric, safe_extra_payment numeric)
```

Параметры со значениями по умолчанию: `p_weekly_living`, `p_reserve`.

Прогнозная обёртка; не замена оперативному статусу.


<a id="fn-fund-event-e24cde05db"></a>

[Исходник SQL](../database/functions/fund_event--e24cde05db.sql)

## fund_event

```sql
public.fund_event(p_event_id bigint, p_from_account_id bigint, p_amount numeric, p_occurred_at timestamp with time zone, p_description text)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_amount`, `p_occurred_at`, `p_description`.

Перевод на платёжный буфер и привязка обеспечения.

Комментарий в БД: Canonical command to secure an event. Creates funding only; never marks the event paid.


<a id="fn-generate-cash-flow-events-5188dc9aeb"></a>

[Исходник SQL](../database/functions/generate_cash_flow_events--5188dc9aeb.sql)

## generate_cash_flow_events

```sql
public.generate_cash_flow_events(from_date date, to_date date)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Создание/синхронизация событий по правилам и банковским графикам; изменяет данные.


<a id="fn-get-account-balance-329abeba8c"></a>

[Исходник SQL](../database/functions/get_account_balance--329abeba8c.sql)

## get_account_balance

```sql
public.get_account_balance(p_account_id bigint, p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Баланс счёта на момент или конец бизнес-дня.


<a id="fn-get-account-balance-654dfdbb2e"></a>

[Исходник SQL](../database/functions/get_account_balance--654dfdbb2e.sql)

## get_account_balance

```sql
public.get_account_balance(p_account_id bigint, p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Баланс счёта на момент или конец бизнес-дня.


<a id="fn-get-actual-cash-4d54a90000"></a>

[Исходник SQL](../database/functions/get_actual_cash--4d54a90000.sql)

## get_actual_cash

```sql
public.get_actual_cash(p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Фактические деньги активных bank/cash счетов.


<a id="fn-get-actual-cash-f161cecaef"></a>

[Исходник SQL](../database/functions/get_actual_cash--f161cecaef.sql)

## get_actual_cash

```sql
public.get_actual_cash(p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Фактические деньги активных bank/cash счетов.


<a id="fn-get-cash-flow-event-coverage-af94ef53c9"></a>

[Исходник SQL](../database/functions/get_cash_flow_event_coverage--af94ef53c9.sql)

## get_cash_flow_event_coverage

```sql
public.get_cash_flow_event_coverage(p_event_id bigint)
RETURNS TABLE(planned_amount numeric, paid_amount numeric, funded_amount numeric, remaining_payment_amount numeric, remaining_funding_amount numeric)
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-cash-flow-event-state-as-of-e6aad22f44"></a>

[Исходник SQL](../database/functions/get_cash_flow_event_state_as_of--e6aad22f44.sql)

## get_cash_flow_event_state_as_of

```sql
public.get_cash_flow_event_state_as_of(p_as_of timestamp with time zone)
RETURNS TABLE(event_id bigint, event_date date, event_type text, amount numeric, description text, account_id bigint, liability_id bigint, status text, paid_amount numeric, funded_amount numeric, cash_committed_amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Суммы и вычисляемое состояние событий на момент времени.


<a id="fn-get-credit-budget-position-a68ed80ef8"></a>

[Исходник SQL](../database/functions/get_credit_budget_position--a68ed80ef8.sql)

## get_credit_budget_position

```sql
public.get_credit_budget_position(p_as_of timestamp with time zone)
RETURNS TABLE(account_id bigint, account_name text, life_spend_total numeric, cash_repayments_total numeric, unsettled_budget_spend numeric, this_week_life_spend numeric, this_week_cash_repayments numeric, this_week_unsettled numeric, carryover_unsettled numeric, strategic_repayments numeric)
```

Параметры со значениями по умолчанию: `p_as_of`.

Отслеживаемые повседневные расходы кредитных карт и их погашения.


<a id="fn-get-credit-cash-reserves-48133ca082"></a>

[Исходник SQL](../database/functions/get_credit_cash_reserves--48133ca082.sql)

## get_credit_cash_reserves

```sql
public.get_credit_cash_reserves(p_as_of timestamp with time zone, p_horizon_end date)
RETURNS TABLE(account_id bigint, unpaid_life numeric, grace_outstanding numeric, scheduled_repayments numeric, additional_reserve numeric)
```

Параметры со значениями по умолчанию: нет.

Дополнительный резерв под непогашенные покупки и grace-движения.

Комментарий в БД: Reserve actual unrepaid daily card spending and explicitly tagged grace draws, net of scheduled repayments already reserved in the horizon.


<a id="fn-get-expense-category-lines-25428b0831"></a>

[Исходник SQL](../database/functions/get_expense_category_lines--25428b0831.sql)

## get_expense_category_lines

```sql
public.get_expense_category_lines(p_start date, p_end date)
RETURNS TABLE(transaction_id bigint, transaction_date date, description text, category_id bigint, category_name text, amount numeric, allocation_source text)
```

Параметры со значениями по умолчанию: нет.

Строки категорий расходов, заменяющие полную сумму при наличии разбиения.


<a id="fn-get-financial-position-d043b30aa9"></a>

[Исходник SQL](../database/functions/get_financial_position--d043b30aa9.sql)

## get_financial_position

```sql
public.get_financial_position(p_as_of date, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-financial-position-6ee5ec6561"></a>

[Исходник SQL](../database/functions/get_financial_position--6ee5ec6561.sql)

## get_financial_position

```sql
public.get_financial_position(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-financial-position-at-9f14d7d31e"></a>

[Исходник SQL](../database/functions/get_financial_position_at--9f14d7d31e.sql)

## get_financial_position_at

```sql
public.get_financial_position_at(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Факт на cutoff и прогноз по целевую дату.

Комментарий в БД: Fact at exact cutoff and forecast to target date. Canonical daily status is get_status_until_next_income.


<a id="fn-get-financial-position-v2-588bed1dca"></a>

[Исходник SQL](../database/functions/get_financial_position_v2--588bed1dca.sql)

## get_financial_position_v2

```sql
public.get_financial_position_v2(p_as_of date, p_default_weekly_budget numeric)
RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Обёртка выбора cutoff для отчёта на дату.


<a id="fn-get-free-cash-5de924fe5e"></a>

[Исходник SQL](../database/functions/get_free_cash--5de924fe5e.sql)

## get_free_cash

```sql
public.get_free_cash(p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Свободные деньги до дохода; не сумма физических остатков.


<a id="fn-get-free-cash-5ed941717d"></a>

[Исходник SQL](../database/functions/get_free_cash--5ed941717d.sql)

## get_free_cash

```sql
public.get_free_cash(p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Свободные деньги до дохода; не сумма физических остатков.

Комментарий в БД: Canonical free cash until next planned income; actual physical cash is get_actual_cash.


<a id="fn-get-income-event-state-as-of-e07cdd98ff"></a>

[Исходник SQL](../database/functions/get_income_event_state_as_of--e07cdd98ff.sql)

## get_income_event_state_as_of

```sql
public.get_income_event_state_as_of(p_as_of timestamp with time zone)
RETURNS TABLE(event_id bigint, received_amount numeric, remaining_amount numeric, derived_status text, last_received_at timestamp with time zone)
```

Параметры со значениями по умолчанию: `p_as_of`.

Полученная и оставшаяся сумма ожидаемых доходов.


<a id="fn-get-liability-balance-4540d0944f"></a>

[Исходник SQL](../database/functions/get_liability_balance--4540d0944f.sql)

## get_liability_balance

```sql
public.get_liability_balance(p_liability_id bigint, p_as_of date)
RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
```

Параметры со значениями по умолчанию: нет.

Существующий контракт расчёта долга; для детализации и признака доступности компонентов см. get_liability_balance_details.


<a id="fn-get-liability-balance-8d1c73d395"></a>

[Исходник SQL](../database/functions/get_liability_balance--8d1c73d395.sql)

## get_liability_balance

```sql
public.get_liability_balance(p_liability_id bigint, p_as_of timestamp with time zone)
RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
```

Параметры со значениями по умолчанию: `p_as_of`.

Существующий контракт расчёта долга; для детализации и признака доступности компонентов см. get_liability_balance_details.

Комментарий в БД: Legacy card model: principal_balance equals total card debt. For accurate components and availability flag use get_liability_balance_details.


<a id="fn-get-liability-balance-details-0017571ee7"></a>

[Исходник SQL](../database/functions/get_liability_balance_details--0017571ee7.sql)

## get_liability_balance_details

```sql
public.get_liability_balance_details(p_liability_id bigint, p_as_of timestamp with time zone)
RETURNS TABLE(total_debt numeric, principal_balance numeric, accrued_interest numeric, fees_due numeric, components_known boolean, components_as_of timestamp with time zone)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-liquidity-until-next-income-5a43c09635"></a>

[Исходник SQL](../database/functions/get_liquidity_until_next_income--5a43c09635.sql)

## get_liquidity_until_next_income

```sql
public.get_liquidity_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, business_date date, next_income_date date, next_income_description text, next_income_amount numeric, actual_cash numeric, required_outflows_before_income numeric, remaining_living_budget numeric, future_living_budget numeric, planned_purchase_reserve numeric, free_cash_until_next_income numeric)
```

Параметры со значениями по умолчанию: `p_as_of`, `p_default_weekly_budget`.

Составляющие свободных денег до ближайшего незавершённого дохода.


<a id="fn-get-living-budget-reserve-e27d063804"></a>

[Исходник SQL](../database/functions/get_living_budget_reserve--e27d063804.sql)

## get_living_budget_reserve

```sql
public.get_living_budget_reserve(p_week_start date, p_as_of timestamp with time zone, p_default_budget numeric)
RETURNS TABLE(budget_amount numeric, spent_amount numeric, earmarked_amount numeric, remaining_reserve numeric, overrun numeric)
```

Параметры со значениями по умолчанию: `p_default_budget`.

Лимит, траты, обеспеченные бюджетные суммы и остаток резерва недели.


<a id="fn-get-obligations-until-next-income-67aba6d215"></a>

[Исходник SQL](../database/functions/get_obligations_until_next_income--67aba6d215.sql)

## get_obligations_until_next_income

```sql
public.get_obligations_until_next_income(p_as_of timestamp with time zone)
RETURNS TABLE(next_income_date date, event_id bigint, event_date date, description text, amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-settlement-attention-8b310d39ab"></a>

[Исходник SQL](../database/functions/get_settlement_attention--8b310d39ab.sql)

## get_settlement_attention

```sql
public.get_settlement_attention(p_as_of date)
RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, paid_amount numeric, funded_amount numeric, cash_still_required numeric, remaining_payment_amount numeric, derived_status text, timing_status text, attention_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-get-status-until-next-income-8d89e6dc13"></a>

[Исходник SQL](../database/functions/get_status_until_next_income--8d89e6dc13.sql)

## get_status_until_next_income

```sql
public.get_status_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS jsonb
```

Параметры со значениями по умолчанию: `p_as_of`, `p_default_weekly_budget`.

Канонический оперативный статус для пользователя. С 11 сентября 2026 возвращает также `previous_day_operations` — полный список операций предыдущего бизнес-дня. [Контракт блока](api.md#status-read).

Комментарий в БД: Canonical operational finance status. Use this instead of get_financial_position/free_cash for user-facing status.


<a id="fn-get-upcoming-payments-cf8a6c80ca"></a>

[Исходник SQL](../database/functions/get_upcoming_payments--cf8a6c80ca.sql)

## get_upcoming_payments

```sql
public.get_upcoming_payments(p_days integer)
RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, secured boolean, security_transaction_id bigint, security_note text)
```

Параметры со значениями по умолчанию: `p_days`.

Неисполненные платежи: сегодня…сегодня+p_days включительно.


<a id="fn-link-funding-183bf77d8a"></a>

[Исходник SQL](../database/functions/link_funding--183bf77d8a.sql)

## link_funding

```sql
public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-link-funding-baaab7d6e0"></a>

[Исходник SQL](../database/functions/link_funding--baaab7d6e0.sql)

## link_funding

```sql
public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric, p_relation_type text)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-normalize-credit-card-payment-semantics-4d193efffb"></a>

[Исходник SQL](../database/functions/normalize_credit_card_payment_semantics--4d193efffb.sql)

## normalize_credit_card_payment_semantics

```sql
public.normalize_credit_card_payment_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-normalize-payment-buffer-funding-semantics-16ab0a0576"></a>

[Исходник SQL](../database/functions/normalize_payment_buffer_funding_semantics--16ab0a0576.sql)

## normalize_payment_buffer_funding_semantics

```sql
public.normalize_payment_buffer_funding_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-normalize-transaction-budget-effect-9e6add9034"></a>

[Исходник SQL](../database/functions/normalize_transaction_budget_effect--9e6add9034.sql)

## normalize_transaction_budget_effect

```sql
public.normalize_transaction_budget_effect()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-rebuild-debt-payment-movements-cadf8bb48d"></a>

[Исходник SQL](../database/functions/rebuild_debt_payment_movements--cadf8bb48d.sql)

## rebuild_debt_payment_movements

```sql
public.rebuild_debt_payment_movements(p_liability_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-reconcile-credit-card-minimum-ea61b8cf4b"></a>

[Исходник SQL](../database/functions/reconcile_credit_card_minimum--ea61b8cf4b.sql)

## reconcile_credit_card_minimum

```sql
public.reconcile_credit_card_minimum(p_event_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-reconcile-credit-card-minimum-from-old-transaction-4945a36f7d"></a>

[Исходник SQL](../database/functions/reconcile_credit_card_minimum_from_old_transaction--4945a36f7d.sql)

## reconcile_credit_card_minimum_from_old_transaction

```sql
public.reconcile_credit_card_minimum_from_old_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-reconcile-credit-card-minimum-from-transaction-189bfba7de"></a>

[Исходник SQL](../database/functions/reconcile_credit_card_minimum_from_transaction--189bfba7de.sql)

## reconcile_credit_card_minimum_from_transaction

```sql
public.reconcile_credit_card_minimum_from_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-reconcile-payment-buffer-funding-from-transaction-2d2145772a"></a>

[Исходник SQL](../database/functions/reconcile_payment_buffer_funding_from_transaction--2d2145772a.sql)

## reconcile_payment_buffer_funding_from_transaction

```sql
public.reconcile_payment_buffer_funding_from_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-refresh-cash-flow-24981a6d0a"></a>

[Исходник SQL](../database/functions/refresh_cash_flow--24981a6d0a.sql)

## refresh_cash_flow

```sql
public.refresh_cash_flow()
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-refresh-cash-flow-event-from-allocation-176c3ff941"></a>

[Исходник SQL](../database/functions/refresh_cash_flow_event_from_allocation--176c3ff941.sql)

## refresh_cash_flow_event_from_allocation

```sql
public.refresh_cash_flow_event_from_allocation()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-refresh-cash-flow-event-status-7a84b59058"></a>

[Исходник SQL](../database/functions/refresh_cash_flow_event_status--7a84b59058.sql)

## refresh_cash_flow_event_status

```sql
public.refresh_cash_flow_event_status(p_event_id bigint)
RETURNS cash_flow_events
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-refresh-cash-flow-security-bef82af046"></a>

[Исходник SQL](../database/functions/refresh_cash_flow_security--bef82af046.sql)

## refresh_cash_flow_security

```sql
public.refresh_cash_flow_security(p_start date, p_end date)
RETURNS integer
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-refresh-event-security-cb28073649"></a>

[Исходник SQL](../database/functions/refresh_event_security--cb28073649.sql)

## refresh_event_security

```sql
public.refresh_event_security()
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-refresh-snapshot-dependents-e774891266"></a>

[Исходник SQL](../database/functions/refresh_snapshot_dependents--e774891266.sql)

## refresh_snapshot_dependents

```sql
public.refresh_snapshot_dependents()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-refresh-transaction-dependents-3513c6b0a2"></a>

[Исходник SQL](../database/functions/refresh_transaction_dependents--3513c6b0a2.sql)

## refresh_transaction_dependents

```sql
public.refresh_transaction_dependents()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-set-credit-card-minimum-613f21d5d7"></a>

[Исходник SQL](../database/functions/set_credit_card_minimum--613f21d5d7.sql)

## set_credit_card_minimum

```sql
public.set_credit_card_minimum(p_liability_id bigint, p_amount numeric, p_due_date date)
RETURNS bigint
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-sync-cash-flow-sources-2ed9ef51b8"></a>

[Исходник SQL](../database/functions/sync_cash_flow_sources--2ed9ef51b8.sql)

## sync_cash_flow_sources

```sql
public.sync_cash_flow_sources()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-sync-debt-payment-movements-e4b6004cb5"></a>

[Исходник SQL](../database/functions/sync_debt_payment_movements--e4b6004cb5.sql)

## sync_debt_payment_movements

```sql
public.sync_debt_payment_movements()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-sync-liability-principal-cache-493f3f0c4a"></a>

[Исходник SQL](../database/functions/sync_liability_principal_cache--493f3f0c4a.sql)

## sync_liability_principal_cache

```sql
public.sync_liability_principal_cache(p_liability_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в исходниках SQL. Отдельный стабильный клиентский контракт здесь не объявлен.


<a id="fn-sync-salary-transaction-to-event-845fb072a1"></a>

[Исходник SQL](../database/functions/sync_salary_transaction_to_event--845fb072a1.sql)

## sync_salary_transaction_to_event

```sql
public.sync_salary_transaction_to_event()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-trg-sync-liability-cache-from-movements-68942a8473"></a>

[Исходник SQL](../database/functions/trg_sync_liability_cache_from_movements--68942a8473.sql)

## trg_sync_liability_cache_from_movements

```sql
public.trg_sync_liability_cache_from_movements()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-trg-sync-revolving-liability-cache-da3ad9487b"></a>

[Исходник SQL](../database/functions/trg_sync_revolving_liability_cache--da3ad9487b.sql)

## trg_sync_revolving_liability_cache

```sql
public.trg_sync_revolving_liability_cache()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-validate-cash-flow-allocation-7bc13b6030"></a>

[Исходник SQL](../database/functions/validate_cash_flow_allocation--7bc13b6030.sql)

## validate_cash_flow_allocation

```sql
public.validate_cash_flow_allocation()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-validate-debt-payment-details-fc68f8438d"></a>

[Исходник SQL](../database/functions/validate_debt_payment_details--fc68f8438d.sql)

## validate_debt_payment_details

```sql
public.validate_debt_payment_details()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-validate-grace-reserve-d63891a4f9"></a>

[Исходник SQL](../database/functions/validate_grace_reserve--d63891a4f9.sql)

## validate_grace_reserve

```sql
public.validate_grace_reserve()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-validate-grace-reserve-deferred-303d13b645"></a>

[Исходник SQL](../database/functions/validate_grace_reserve_deferred--303d13b645.sql)

## validate_grace_reserve_deferred

```sql
public.validate_grace_reserve_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


<a id="fn-validate-transaction-category-allocations-deferred-2a4024676f"></a>

[Исходник SQL](../database/functions/validate_transaction_category_allocations_deferred--2a4024676f.sql)

## validate_transaction_category_allocations_deferred

```sql
public.validate_transaction_category_allocations_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.

