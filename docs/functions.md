# Каталог функций

В каталоге 76 сигнатур схемы `public`, включая перегрузки и триггерные функции. Сигнатуры и возвращаемые типы получены из PostgreSQL 7 сентября 2026 года. Это инвентаризация, а не обещание стабильности всех внутренних вызовов. Для интеграции начинайте с [прикладного API](api.md).

В сигнатурах ниже значения DEFAULT намеренно опущены; параметры с defaults перечислены отдельно. Для фактического вызова используйте именованные аргументы и явные типы. Полные тела функций и миграции в этот пакет не включены.

Все обследованные функции исполняются с правами вызывающего (`SECURITY INVOKER`). Метка `VOLATILE` сама по себе не доказывает изменение данных; для административных и триггерных функций необходимо читать реализацию.

## Навигация

| Функция | Возвращает | Volatility |
|---|---|---|
| `apply_event_payment_budget_semantics()` | `trigger` | VOLATILE |
| `assert_free_cash_invariant(p_before numeric, p_after numeric, p_context text, p_tolerance numeric)` | `void` | IMMUTABLE |
| `business_day_on_or_before(d date)` | `date` | IMMUTABLE |
| `clear_credit_card_minimum_allocations()` | `trigger` | VOLATILE |
| `clear_payment_buffer_funding_allocations()` | `trigger` | VOLATILE |
| `complete_income_event(p_event_id bigint, p_completed_at timestamp with time zone)` | `void` | VOLATILE |
| `correct_finance_transaction(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb, p_debt_details jsonb, p_event_allocations jsonb, p_receipt_patch jsonb)` | `transactions` | VOLATILE |
| `execute_event(p_event_id bigint, p_from_account_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)` | `bigint` | VOLATILE |
| `execute_installment_payment(p_event_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)` | `bigint` | VOLATILE |
| `finance_business_date(p_ts timestamp with time zone)` | `date` | STABLE |
| `finance_command(p_request_key text, p_command text, p_args jsonb)` | `bigint` | VOLATILE |
| `finance_data_issues()` | `TABLE(code text, entity_id bigint, details jsonb)` | STABLE |
| `finance_day_end(p_date date)` | `timestamp with time zone` | STABLE |
| `finance_day_start(p_date date)` | `timestamp with time zone` | STABLE |
| `finance_integrity_check(p_as_of timestamp with time zone)` | `TABLE(severity text, code text, entity_type text, entity_id bigint, message text, details jsonb)` | STABLE |
| `finance_setting_numeric(p_key text, p_default numeric)` | `numeric` | STABLE |
| `finance_setting_text(p_key text, p_default text)` | `text` | STABLE |
| `finance_validate_data_deferred()` | `trigger` | VOLATILE |
| `finance_write_lock()` | `trigger` | VOLATILE |
| `forecast_free_cash(p_target_date date, p_weekly_living numeric, p_reserve numeric)` | `TABLE(current_free_cash numeric, planned_income numeric, secured_outflows numeric, unsecure_outflows numeric, remaining_living_budget numeric, living_budget_overrun numeric, future_living_budget numeric, projected_free_cash numeric, safe_extra_payment numeric)` | STABLE |
| `fund_event(p_event_id bigint, p_from_account_id bigint, p_amount numeric, p_occurred_at timestamp with time zone, p_description text)` | `bigint` | VOLATILE |
| `generate_cash_flow_events(from_date date, to_date date)` | `void` | VOLATILE |
| `get_account_balance(p_account_id bigint, p_as_of date)` | `numeric` | STABLE |
| `get_account_balance(p_account_id bigint, p_as_of timestamp with time zone)` | `numeric` | STABLE |
| `get_actual_cash(p_as_of date)` | `numeric` | STABLE |
| `get_actual_cash(p_as_of timestamp with time zone)` | `numeric` | STABLE |
| `get_cash_flow_event_coverage(p_event_id bigint)` | `TABLE(planned_amount numeric, paid_amount numeric, funded_amount numeric, remaining_payment_amount numeric, remaining_funding_amount numeric)` | STABLE |
| `get_cash_flow_event_state_as_of(p_as_of timestamp with time zone)` | `TABLE(event_id bigint, event_date date, event_type text, amount numeric, description text, account_id bigint, liability_id bigint, status text, paid_amount numeric, funded_amount numeric, cash_committed_amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)` | STABLE |
| `get_credit_budget_position(p_as_of timestamp with time zone)` | `TABLE(account_id bigint, account_name text, life_spend_total numeric, cash_repayments_total numeric, unsettled_budget_spend numeric, this_week_life_spend numeric, this_week_cash_repayments numeric, this_week_unsettled numeric, carryover_unsettled numeric, strategic_repayments numeric)` | STABLE |
| `get_credit_cash_reserves(p_as_of timestamp with time zone, p_horizon_end date)` | `TABLE(account_id bigint, unpaid_life numeric, grace_outstanding numeric, scheduled_repayments numeric, additional_reserve numeric)` | STABLE |
| `get_expense_category_lines(p_start date, p_end date)` | `TABLE(transaction_id bigint, transaction_date date, description text, category_id bigint, category_name text, amount numeric, allocation_source text)` | STABLE |
| `get_financial_position(p_as_of date, p_default_weekly_budget numeric)` | `TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)` | STABLE |
| `get_financial_position(p_as_of timestamp with time zone, p_default_weekly_budget numeric)` | `TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)` | STABLE |
| `get_financial_position_at(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric)` | `TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)` | STABLE |
| `get_financial_position_v2(p_as_of date, p_default_weekly_budget numeric)` | `TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)` | STABLE |
| `get_free_cash(p_as_of date)` | `numeric` | STABLE |
| `get_free_cash(p_as_of timestamp with time zone)` | `numeric` | STABLE |
| `get_income_event_state_as_of(p_as_of timestamp with time zone)` | `TABLE(event_id bigint, received_amount numeric, remaining_amount numeric, derived_status text, last_received_at timestamp with time zone)` | STABLE |
| `get_liability_balance(p_liability_id bigint, p_as_of date)` | `TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)` | STABLE |
| `get_liability_balance(p_liability_id bigint, p_as_of timestamp with time zone)` | `TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)` | STABLE |
| `get_liability_balance_details(p_liability_id bigint, p_as_of timestamp with time zone)` | `TABLE(total_debt numeric, principal_balance numeric, accrued_interest numeric, fees_due numeric, components_known boolean, components_as_of timestamp with time zone)` | STABLE |
| `get_liquidity_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)` | `TABLE(as_of timestamp with time zone, business_date date, next_income_date date, next_income_description text, next_income_amount numeric, actual_cash numeric, required_outflows_before_income numeric, remaining_living_budget numeric, future_living_budget numeric, planned_purchase_reserve numeric, free_cash_until_next_income numeric)` | STABLE |
| `get_living_budget_reserve(p_week_start date, p_as_of timestamp with time zone, p_default_budget numeric)` | `TABLE(budget_amount numeric, spent_amount numeric, earmarked_amount numeric, remaining_reserve numeric, overrun numeric)` | STABLE |
| `get_obligations_until_next_income(p_as_of timestamp with time zone)` | `TABLE(next_income_date date, event_id bigint, event_date date, description text, amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)` | STABLE |
| `get_settlement_attention(p_as_of date)` | `TABLE(event_id bigint, event_date date, description text, amount numeric, paid_amount numeric, funded_amount numeric, cash_still_required numeric, remaining_payment_amount numeric, derived_status text, timing_status text, attention_status text)` | STABLE |
| `get_status_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)` | `jsonb` | STABLE |
| `get_upcoming_payments(p_days integer)` | `TABLE(event_id bigint, event_date date, description text, amount numeric, secured boolean, security_transaction_id bigint, security_note text)` | STABLE |
| `link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric)` | `void` | VOLATILE |
| `link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric, p_relation_type text)` | `void` | VOLATILE |
| `normalize_credit_card_payment_semantics()` | `trigger` | VOLATILE |
| `normalize_payment_buffer_funding_semantics()` | `trigger` | VOLATILE |
| `normalize_transaction_budget_effect()` | `trigger` | VOLATILE |
| `rebuild_debt_payment_movements(p_liability_id bigint)` | `void` | VOLATILE |
| `reconcile_credit_card_minimum(p_event_id bigint)` | `void` | VOLATILE |
| `reconcile_credit_card_minimum_from_old_transaction()` | `trigger` | VOLATILE |
| `reconcile_credit_card_minimum_from_transaction()` | `trigger` | VOLATILE |
| `reconcile_payment_buffer_funding_from_transaction()` | `trigger` | VOLATILE |
| `refresh_cash_flow()` | `void` | VOLATILE |
| `refresh_cash_flow_event_from_allocation()` | `trigger` | VOLATILE |
| `refresh_cash_flow_event_status(p_event_id bigint)` | `cash_flow_events` | VOLATILE |
| `refresh_cash_flow_security(p_start date, p_end date)` | `integer` | VOLATILE |
| `refresh_event_security()` | `void` | VOLATILE |
| `refresh_snapshot_dependents()` | `trigger` | VOLATILE |
| `refresh_transaction_dependents()` | `trigger` | VOLATILE |
| `set_credit_card_minimum(p_liability_id bigint, p_amount numeric, p_due_date date)` | `bigint` | VOLATILE |
| `sync_cash_flow_sources()` | `trigger` | VOLATILE |
| `sync_debt_payment_movements()` | `trigger` | VOLATILE |
| `sync_liability_principal_cache(p_liability_id bigint)` | `void` | VOLATILE |
| `sync_salary_transaction_to_event()` | `trigger` | VOLATILE |
| `trg_sync_liability_cache_from_movements()` | `trigger` | VOLATILE |
| `trg_sync_revolving_liability_cache()` | `trigger` | VOLATILE |
| `validate_cash_flow_allocation()` | `trigger` | VOLATILE |
| `validate_debt_payment_details()` | `trigger` | VOLATILE |
| `validate_grace_reserve()` | `trigger` | VOLATILE |
| `validate_grace_reserve_deferred()` | `trigger` | VOLATILE |
| `validate_transaction_category_allocations_deferred()` | `trigger` | VOLATILE |

## apply_event_payment_budget_semantics

```sql
public.apply_event_payment_budget_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## assert_free_cash_invariant

```sql
public.assert_free_cash_invariant(p_before numeric, p_after numeric, p_context text, p_tolerance numeric)
RETURNS void
```

Параметры со значениями по умолчанию: `p_tolerance`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## business_day_on_or_before

```sql
public.business_day_on_or_before(d date)
RETURNS date
```

Параметры со значениями по умолчанию: нет.

Перенос только субботы/воскресенья на пятницу; без праздничного календаря.


## clear_credit_card_minimum_allocations

```sql
public.clear_credit_card_minimum_allocations()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## clear_payment_buffer_funding_allocations

```sql
public.clear_payment_buffer_funding_allocations()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## complete_income_event

```sql
public.complete_income_event(p_event_id bigint, p_completed_at timestamp with time zone)
RETURNS void
```

Параметры со значениями по умолчанию: `p_completed_at`.

Подтверждение завершения дохода после хотя бы одного зачисления.


## correct_finance_transaction

```sql
public.correct_finance_transaction(p_transaction_id bigint, p_patch jsonb, p_category_allocations jsonb, p_debt_details jsonb, p_event_allocations jsonb, p_receipt_patch jsonb)
RETURNS transactions
```

Параметры со значениями по умолчанию: `p_category_allocations`, `p_debt_details`, `p_event_allocations`, `p_receipt_patch`.

Атомарное исправление операции и переданных зависимых разбиений.

Комментарий в БД: Atomic correction. Supply replacement breakdowns when changing amounts; deferred constraints reject incomplete corrections.


## execute_event

```sql
public.execute_event(p_event_id bigint, p_from_account_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_from_account_id`, `p_occurred_at`, `p_actual_amount`, `p_principal_amount`, `p_interest_amount`, `p_fee_amount`.

Фактическое исполнение расходного события.

Комментарий в БД: Canonical command to confirm actual event execution/payment.


## execute_installment_payment

```sql
public.execute_installment_payment(p_event_id bigint, p_occurred_at timestamp with time zone, p_actual_amount numeric, p_principal_amount numeric, p_interest_amount numeric, p_fee_amount numeric)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_occurred_at`, `p_actual_amount`, `p_principal_amount`, `p_interest_amount`, `p_fee_amount`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## finance_business_date

```sql
public.finance_business_date(p_ts timestamp with time zone)
RETURNS date
```

Параметры со значениями по умолчанию: `p_ts`.

Бизнес-дата момента времени.


## finance_command

```sql
public.finance_command(p_request_key text, p_command text, p_args jsonb)
RETURNS bigint
```

Параметры со значениями по умолчанию: нет.

Предпочтительная обёртка записи с ключом повторного запроса. См. прикладной API.

Комментарий в БД: Idempotent entry point for record_transaction, fund_event and execute_event. Reuse request key on retry; different payload with same key is rejected.


## finance_data_issues

```sql
public.finance_data_issues()
RETURNS TABLE(code text, entity_id bigint, details jsonb)
```

Параметры со значениями по умолчанию: нет.

Структурные/семантические проблемы текущих данных.


## finance_day_end

```sql
public.finance_day_end(p_date date)
RETURNS timestamp with time zone
```

Параметры со значениями по умолчанию: нет.

Конец дня в business_timezone с точностью до микросекунды.


## finance_day_start

```sql
public.finance_day_start(p_date date)
RETURNS timestamp with time zone
```

Параметры со значениями по умолчанию: нет.

Начало дня в business_timezone.


## finance_integrity_check

```sql
public.finance_integrity_check(p_as_of timestamp with time zone)
RETURNS TABLE(severity text, code text, entity_type text, entity_id bigint, message text, details jsonb)
```

Параметры со значениями по умолчанию: `p_as_of`.

Диагностика согласованности с severity, code и details.


## finance_setting_numeric

```sql
public.finance_setting_numeric(p_key text, p_default numeric)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_default`.

Числовая настройка JSONB с fallback.


## finance_setting_text

```sql
public.finance_setting_text(p_key text, p_default text)
RETURNS text
```

Параметры со значениями по умолчанию: `p_default`.

Текстовая настройка JSONB с fallback.


## finance_validate_data_deferred

```sql
public.finance_validate_data_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## finance_write_lock

```sql
public.finance_write_lock()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## forecast_free_cash

```sql
public.forecast_free_cash(p_target_date date, p_weekly_living numeric, p_reserve numeric)
RETURNS TABLE(current_free_cash numeric, planned_income numeric, secured_outflows numeric, unsecure_outflows numeric, remaining_living_budget numeric, living_budget_overrun numeric, future_living_budget numeric, projected_free_cash numeric, safe_extra_payment numeric)
```

Параметры со значениями по умолчанию: `p_weekly_living`, `p_reserve`.

Прогнозная обёртка; не замена оперативному статусу.


## fund_event

```sql
public.fund_event(p_event_id bigint, p_from_account_id bigint, p_amount numeric, p_occurred_at timestamp with time zone, p_description text)
RETURNS bigint
```

Параметры со значениями по умолчанию: `p_amount`, `p_occurred_at`, `p_description`.

Перевод на платёжный буфер и привязка обеспечения.

Комментарий в БД: Canonical command to secure an event. Creates funding only; never marks the event paid.


## generate_cash_flow_events

```sql
public.generate_cash_flow_events(from_date date, to_date date)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Создание/синхронизация событий по правилам и банковским графикам; изменяет данные.


## get_account_balance

```sql
public.get_account_balance(p_account_id bigint, p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Баланс счёта на момент или конец бизнес-дня.


## get_account_balance

```sql
public.get_account_balance(p_account_id bigint, p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Баланс счёта на момент или конец бизнес-дня.


## get_actual_cash

```sql
public.get_actual_cash(p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Фактические деньги активных bank/cash счетов.


## get_actual_cash

```sql
public.get_actual_cash(p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Фактические деньги активных bank/cash счетов.


## get_cash_flow_event_coverage

```sql
public.get_cash_flow_event_coverage(p_event_id bigint)
RETURNS TABLE(planned_amount numeric, paid_amount numeric, funded_amount numeric, remaining_payment_amount numeric, remaining_funding_amount numeric)
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_cash_flow_event_state_as_of

```sql
public.get_cash_flow_event_state_as_of(p_as_of timestamp with time zone)
RETURNS TABLE(event_id bigint, event_date date, event_type text, amount numeric, description text, account_id bigint, liability_id bigint, status text, paid_amount numeric, funded_amount numeric, cash_committed_amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Суммы и вычисляемое состояние событий на момент времени.


## get_credit_budget_position

```sql
public.get_credit_budget_position(p_as_of timestamp with time zone)
RETURNS TABLE(account_id bigint, account_name text, life_spend_total numeric, cash_repayments_total numeric, unsettled_budget_spend numeric, this_week_life_spend numeric, this_week_cash_repayments numeric, this_week_unsettled numeric, carryover_unsettled numeric, strategic_repayments numeric)
```

Параметры со значениями по умолчанию: `p_as_of`.

Отслеживаемые повседневные расходы кредитных карт и их погашения.


## get_credit_cash_reserves

```sql
public.get_credit_cash_reserves(p_as_of timestamp with time zone, p_horizon_end date)
RETURNS TABLE(account_id bigint, unpaid_life numeric, grace_outstanding numeric, scheduled_repayments numeric, additional_reserve numeric)
```

Параметры со значениями по умолчанию: нет.

Дополнительный резерв под непогашенные покупки и grace-движения.

Комментарий в БД: Reserve actual unrepaid daily card spending and explicitly tagged grace draws, net of scheduled repayments already reserved in the horizon.


## get_expense_category_lines

```sql
public.get_expense_category_lines(p_start date, p_end date)
RETURNS TABLE(transaction_id bigint, transaction_date date, description text, category_id bigint, category_name text, amount numeric, allocation_source text)
```

Параметры со значениями по умолчанию: нет.

Строки категорий расходов, заменяющие полную сумму при наличии разбиения.


## get_financial_position

```sql
public.get_financial_position(p_as_of date, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_financial_position

```sql
public.get_financial_position(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, actual_cash numeric, projected_cash numeric, current_week_budget numeric, remaining_living_budget numeric, living_budget_overrun numeric, active_purchase_reserve numeric, unsecured_obligations numeric, secured_obligations numeric, credit_expenses_over_budget numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_financial_position_at

```sql
public.get_financial_position_at(p_as_of date, p_cutoff timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Факт на cutoff и прогноз по целевую дату.

Комментарий в БД: Fact at exact cutoff and forecast to target date. Canonical daily status is get_status_until_next_income.


## get_financial_position_v2

```sql
public.get_financial_position_v2(p_as_of date, p_default_weekly_budget numeric)
RETURNS TABLE(as_of date, actual_cash numeric, expected_income numeric, required_cash_flow_outflows numeric, secured_future_outflows numeric, projected_cash numeric, current_week_budget numeric, current_week_spend numeric, remaining_living_budget numeric, future_living_budget numeric, credit_budget_reserve numeric, credit_budget_additional_reserve numeric, planned_purchase_reserve numeric, free_cash numeric)
```

Параметры со значениями по умолчанию: `p_default_weekly_budget`.

Обёртка выбора cutoff для отчёта на дату.


## get_free_cash

```sql
public.get_free_cash(p_as_of date)
RETURNS numeric
```

Параметры со значениями по умолчанию: нет.

Свободные деньги до дохода; не сумма физических остатков.


## get_free_cash

```sql
public.get_free_cash(p_as_of timestamp with time zone)
RETURNS numeric
```

Параметры со значениями по умолчанию: `p_as_of`.

Свободные деньги до дохода; не сумма физических остатков.

Комментарий в БД: Canonical free cash until next planned income; actual physical cash is get_actual_cash.


## get_income_event_state_as_of

```sql
public.get_income_event_state_as_of(p_as_of timestamp with time zone)
RETURNS TABLE(event_id bigint, received_amount numeric, remaining_amount numeric, derived_status text, last_received_at timestamp with time zone)
```

Параметры со значениями по умолчанию: `p_as_of`.

Полученная и оставшаяся сумма ожидаемых доходов.


## get_liability_balance

```sql
public.get_liability_balance(p_liability_id bigint, p_as_of date)
RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
```

Параметры со значениями по умолчанию: нет.

Существующий контракт расчёта долга; для детализации и признака доступности компонентов см. get_liability_balance_details.


## get_liability_balance

```sql
public.get_liability_balance(p_liability_id bigint, p_as_of timestamp with time zone)
RETURNS TABLE(principal_balance numeric, accrued_interest numeric, fees_due numeric, total_debt numeric)
```

Параметры со значениями по умолчанию: `p_as_of`.

Существующий контракт расчёта долга; для детализации и признака доступности компонентов см. get_liability_balance_details.

Комментарий в БД: Legacy card model: principal_balance equals total card debt. For accurate components and availability flag use get_liability_balance_details.


## get_liability_balance_details

```sql
public.get_liability_balance_details(p_liability_id bigint, p_as_of timestamp with time zone)
RETURNS TABLE(total_debt numeric, principal_balance numeric, accrued_interest numeric, fees_due numeric, components_known boolean, components_as_of timestamp with time zone)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_liquidity_until_next_income

```sql
public.get_liquidity_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS TABLE(as_of timestamp with time zone, business_date date, next_income_date date, next_income_description text, next_income_amount numeric, actual_cash numeric, required_outflows_before_income numeric, remaining_living_budget numeric, future_living_budget numeric, planned_purchase_reserve numeric, free_cash_until_next_income numeric)
```

Параметры со значениями по умолчанию: `p_as_of`, `p_default_weekly_budget`.

Составляющие свободных денег до ближайшего незавершённого дохода.


## get_living_budget_reserve

```sql
public.get_living_budget_reserve(p_week_start date, p_as_of timestamp with time zone, p_default_budget numeric)
RETURNS TABLE(budget_amount numeric, spent_amount numeric, earmarked_amount numeric, remaining_reserve numeric, overrun numeric)
```

Параметры со значениями по умолчанию: `p_default_budget`.

Лимит, траты, обеспеченные бюджетные суммы и остаток резерва недели.


## get_obligations_until_next_income

```sql
public.get_obligations_until_next_income(p_as_of timestamp with time zone)
RETURNS TABLE(next_income_date date, event_id bigint, event_date date, description text, amount numeric, remaining_payment_amount numeric, cash_still_required numeric, derived_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_settlement_attention

```sql
public.get_settlement_attention(p_as_of date)
RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, paid_amount numeric, funded_amount numeric, cash_still_required numeric, remaining_payment_amount numeric, derived_status text, timing_status text, attention_status text)
```

Параметры со значениями по умолчанию: `p_as_of`.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## get_status_until_next_income

```sql
public.get_status_until_next_income(p_as_of timestamp with time zone, p_default_weekly_budget numeric)
RETURNS jsonb
```

Параметры со значениями по умолчанию: `p_as_of`, `p_default_weekly_budget`.

Канонический оперативный статус для пользователя.

Комментарий в БД: Canonical operational finance status. Use this instead of get_financial_position/free_cash for user-facing status.


## get_upcoming_payments

```sql
public.get_upcoming_payments(p_days integer)
RETURNS TABLE(event_id bigint, event_date date, description text, amount numeric, secured boolean, security_transaction_id bigint, security_note text)
```

Параметры со значениями по умолчанию: `p_days`.

Неисполненные платежи: сегодня…сегодня+p_days включительно.


## link_funding

```sql
public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## link_funding

```sql
public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric, p_relation_type text)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## normalize_credit_card_payment_semantics

```sql
public.normalize_credit_card_payment_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## normalize_payment_buffer_funding_semantics

```sql
public.normalize_payment_buffer_funding_semantics()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## normalize_transaction_budget_effect

```sql
public.normalize_transaction_budget_effect()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## rebuild_debt_payment_movements

```sql
public.rebuild_debt_payment_movements(p_liability_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## reconcile_credit_card_minimum

```sql
public.reconcile_credit_card_minimum(p_event_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## reconcile_credit_card_minimum_from_old_transaction

```sql
public.reconcile_credit_card_minimum_from_old_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## reconcile_credit_card_minimum_from_transaction

```sql
public.reconcile_credit_card_minimum_from_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## reconcile_payment_buffer_funding_from_transaction

```sql
public.reconcile_payment_buffer_funding_from_transaction()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## refresh_cash_flow

```sql
public.refresh_cash_flow()
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## refresh_cash_flow_event_from_allocation

```sql
public.refresh_cash_flow_event_from_allocation()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## refresh_cash_flow_event_status

```sql
public.refresh_cash_flow_event_status(p_event_id bigint)
RETURNS cash_flow_events
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## refresh_cash_flow_security

```sql
public.refresh_cash_flow_security(p_start date, p_end date)
RETURNS integer
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## refresh_event_security

```sql
public.refresh_event_security()
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## refresh_snapshot_dependents

```sql
public.refresh_snapshot_dependents()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## refresh_transaction_dependents

```sql
public.refresh_transaction_dependents()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## set_credit_card_minimum

```sql
public.set_credit_card_minimum(p_liability_id bigint, p_amount numeric, p_due_date date)
RETURNS bigint
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## sync_cash_flow_sources

```sql
public.sync_cash_flow_sources()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## sync_debt_payment_movements

```sql
public.sync_debt_payment_movements()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## sync_liability_principal_cache

```sql
public.sync_liability_principal_cache(p_liability_id bigint)
RETURNS void
```

Параметры со значениями по умолчанию: нет.

Дополнительная функция расчёта, синхронизации или совместимости. До прямого использования проверьте тело функции и вызывающие места в миграциях. Отдельный стабильный клиентский контракт здесь не объявлен.


## sync_salary_transaction_to_event

```sql
public.sync_salary_transaction_to_event()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## trg_sync_liability_cache_from_movements

```sql
public.trg_sync_liability_cache_from_movements()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## trg_sync_revolving_liability_cache

```sql
public.trg_sync_revolving_liability_cache()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## validate_cash_flow_allocation

```sql
public.validate_cash_flow_allocation()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## validate_debt_payment_details

```sql
public.validate_debt_payment_details()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## validate_grace_reserve

```sql
public.validate_grace_reserve()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## validate_grace_reserve_deferred

```sql
public.validate_grace_reserve_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.


## validate_transaction_category_allocations_deferred

```sql
public.validate_transaction_category_allocations_deferred()
RETURNS trigger
```

Параметры со значениями по умолчанию: нет.

Триггерная функция. Вызывается механизмом триггеров; не использовать как пользовательскую команду. Привязки приведены в справочнике базы.

