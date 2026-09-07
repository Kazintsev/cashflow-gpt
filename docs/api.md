# Прикладной API и SQL-примеры

Контракты ниже сверены с текущими определениями функций. Упоминание «API» означает рекомендуемый прикладной маршрут; отдельный HTTP-сервис и конфигурация клиентского адаптера в пакет не входят.

## Правила примеров

- Запросы чтения используют реальные имена объектов.
- Примеры записи используют параметры `:request_key`, `:account_id` и другие. Это обозначения привязанных параметров клиента; они не выполняются в SQL Editor без адаптации.
- Учебные суммы вымышлены. Примеры записи в рабочей базе не исполнялись.
- У одного бизнес-запроса при повторе должны оставаться прежними ключ и все аргументы, включая время. Для другой покупки используется новый ключ.

## 1. Оперативный статус

```sql
select public.get_status_until_next_income(
  p_as_of => now(),
  p_default_weekly_budget => null
);
```

`null` в параметре бюджета означает использование настроек. Возвращается JSONB со следующими ключами:

| Ключ | Содержимое |
|---|---|
| `status_version` | Версия контракта; обследованное значение — `cashflow_until_next_income_v3` |
| `as_of`, `business_date` | Момент расчёта и бизнес-дата |
| `integrity_ok` | Нет диагностических записей уровня `error` |
| `integrity_issues` | Массив проблем: severity, code, entity_type, entity_id, message, details |
| `cash` | actual_cash и breakdown по активным банковским/наличным счетам |
| `next_income` | date, description, amount; отсутствие горизонта обозначено null |
| `weekly_budget` | week_start, budget, spend, remaining, overrun |
| `liquidity` | free_cash_until_next_income и пять составляющих резервов/выплат |
| `today` | Неисполненные расходные события сегодня |
| `controls` | Прошедшие неисполненные расходные события |
| `obligations_until_next_income` | События после сегодня и строго до даты дохода |

Поля `liquidity`:

- `free_cash_until_next_income`;
- `required_outflows_before_income`;
- `remaining_living_budget`;
- `future_living_budget`;
- `planned_purchase_reserve`;
- `credit_reserve`.

В элементах `today` и `obligations_until_next_income` поле `amount` содержит остаток к оплате, а не исходную полную сумму события. `cash_still_required` показывает ещё необходимую сумму из cash. Дополнительно возвращаются `coverage`, `derived_status`, `living_budget_exempt` и `counts_against_free_cash`.

У `controls` вместо `coverage` используется `attention`: `requires_action` или `secured_unconfirmed`.

Предупреждения возможны и при `integrity_ok=true`. При ошибке вызова нельзя выдавать расчёт по другим полям за результат этого контракта.

## 2. Ближайшие платежи и точные границы

```sql
select * from public.get_upcoming_payments(10);
```

Текущая функция выбирает даты **от сегодня до сегодня + 10 включительно**, то есть 11 календарных дат. Она исключает `executed` и `cancelled`. Поле `amount` здесь — исходная сумма события.

Для ровно десяти календарных дат, начиная с сегодня, включая исполненные события:

```sql
with p as (
  select now() as as_of,
         public.finance_business_date(now()) as date_from
)
select s.event_id, s.event_date, s.description,
       s.amount, s.paid_amount, s.funded_amount,
       s.remaining_payment_amount, s.cash_still_required,
       s.derived_status
from p
cross join lateral public.get_cash_flow_event_state_as_of(p.as_of) s
where s.event_date >= p.date_from
  and s.event_date < p.date_from + 10
  and s.event_type in ('expense', 'debt_payment', 'planned_expense')
  and s.derived_status <> 'cancelled'
order by s.event_date, s.event_id;
```

Если пользователь просит также отменённые события, уберите соответствующий фильтр. Для «завтра и следующие девять дней» нужно изменить нижнюю и верхнюю границы, а не только название отчёта.

## 3. Траты бюджета по категориям

```sql
with p as (
  select now() as as_of,
         public.finance_business_date(now()) as today
)
select coalesce(l.category_name, 'Без категории') as category,
       sum(l.amount) as amount
from p
cross join lateral public.get_expense_category_lines(
  date_trunc('week', p.today)::date, p.today
) l
join public.transactions t on t.id = l.transaction_id
where t.budget_effect = 'life'
  and t.occurred_at <= p.as_of
group by coalesce(l.category_name, 'Без категории')
order by amount desc, category;
```

Сама `get_expense_category_lines` не фильтрует `life` и не принимает временную границу. Эти условия добавляет вызывающий запрос. Если есть разбиение категорий, функция возвращает его вместо полной суммы операции.

## 4. Запись операции

```sql
select public.finance_command(
  :request_key,
  'record_transaction',
  jsonb_build_object(
    'transaction_type', 'expense',
    'amount', 450,
    'currency', 'RUB',
    'description', 'Учебный обед',
    'from_account_id', :account_id,
    'category_id', :category_id,
    'occurred_at', :occurred_at,
    'budget_effect', 'life'
  )
);
```

Результат — ID операции `bigint`.

| Аргумент JSON | Назначение |
|---|---|
| `transaction_type`, `amount` | Тип и положительная сумма |
| `from_account_id`, `to_account_id` | Направление денег; допустимость зависит от типа |
| `occurred_at`, `transaction_date` | Момент и бизнес-дата; должны согласовываться |
| `currency` | Только RUB |
| `category_id`, `description`, `notes` | Классификация и пояснение |
| `budget_effect` | life / excluded / none |
| `liability_id` | Связанный долг |
| `salary_component`, `salary_period_start`, `income_event_id` | Разметка и связь дохода |
| `category_allocations` | Массив {category_id, amount} |
| `event_allocations` | Массив {event_id, amount, relation_type} |
| `debt_details` | {principal_amount, interest_amount, fee_amount, event_id} |
| `reserve_effect`, `reserve_cycle`, `reserve_due_date`, `reserve_liability_id` | Разметка grace-движений |

Если время не передано, используется `now()`; при переданной только дате — полдень бизнес-дня. Для точного учёта передавайте время явно.

В `record_transaction` категория и счёт по названию не разрешаются автоматически. Сначала найдите правильные ID. При неизвестном счёте/категории ассистент должен уточнить данные.

## 5. Обеспечение и исполнение через тот же маршрут

`finance_command` принимает ровно три команды:

| Команда | Поля `p_args` |
|---|---|
| `record_transaction` | Поля операции и допустимые вложенные разбиения |
| `fund_event` | event_id, from_account_id, amount, occurred_at, description |
| `execute_event` | event_id, from_account_id, amount, occurred_at, principal_amount, interest_amount, fee_amount |

В обёртке используется ключ `amount`, хотя у прямой функции исполнения параметр называется `p_actual_amount`.

`fund_event` переводит деньги с активного `bank/cash` на активный `payment_buffer` и связывает перевод с событием. Для карты с прямым погашением этот маршрут не подходит.

`execute_event` создаёт оплату. Для кредита с графиком используется платёжный буфер; для кредитной карты нужен исходный `bank/cash` счёт. Частичный платёж по графику требует явной разбивки суммы. При неизвестной разбивке процентного кредита функция выдаёт ошибку.

`event_allocations` и `debt_details` в обёртке допустимы только с `record_transaction`. Разметка grace-движений также требует этого маршрута.

## 6. Исправление

```sql
select public.correct_finance_transaction(
  p_transaction_id => :transaction_id,
  p_patch => jsonb_build_object('from_account_id', :cash_account_id)
);
```

Функция возвращает строку `transactions`. Она не создаёт отдельную компенсирующую операцию и не является журналом неизменяемых версий.

При изменении связанных данных:

| Параметр | SQL NULL | Пустой/иной JSON |
|---|---|---|
| `p_category_allocations` | Сохранить разбиение | `[]` удалить; массив заменить |
| `p_event_allocations` | Сохранить связи | `[]` удалить; массив заменить |
| `p_debt_details` | Сохранить детализацию | JSON `null` удалить; объект заменить |
| `p_receipt_patch` | Не менять чек | Объект: total_amount, purchase_at, merchant_name |

Пустой объект `{}` для `p_debt_details` не означает удаление: он пытается создать нулевую детализацию и может нарушить ограничение.

При наличии нескольких зависимостей исправляйте их в одном вызове. Если одновременно менять дату и время, они должны совпадать в бизнес-часовом поясе. Изменение только одного поля синхронизируется триггером.

Исправление не переписывает сохранённый исходный `request_payload`. Повтор старого запроса с прежним ключом возвращает ID существующей, уже исправленной операции; новые аргументы с тем же ключом будут отклонены.

## 7. Проверки

```sql
select * from public.finance_integrity_check(now());
select * from public.finance_data_issues();
```

Это чтение. Возвращённые `details` могут содержать личные данные, поэтому их нельзя целиком прикладывать к публичному issue.

## 8. Прогноз

Параметризованный пример, где `:target_date` — дата, а `:cutoff` — точный момент:

```sql
select *
from public.get_financial_position_at(
  cast(:target_date as date),
  cast(:cutoff as timestamptz),
  null
);
```

Различайте прогноз и статус до дохода. Полный перечень перегрузок и возвращаемых полей — в [каталоге функций](functions.md).
