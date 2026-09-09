CREATE OR REPLACE FUNCTION public.finance_integrity_check(p_as_of timestamp with time zone DEFAULT now())
 RETURNS TABLE(severity text, code text, entity_type text, entity_id bigint, message text, details jsonb)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
with st as (
  select * from public.get_cash_flow_event_state_as_of(p_as_of)
), base as (
  select e.*,s.paid_amount,s.funded_amount,s.cash_committed_amount,s.remaining_payment_amount,s.cash_still_required,s.derived_status
  from public.cash_flow_events e join st s on s.event_id=e.id
), allocation_semantics as (
  select f.id allocation_id,f.cash_flow_event_id,f.transaction_id,f.relation_type,t.transaction_type,
         t.from_account_id,t.to_account_id,fa.account_type from_type,ta.account_type to_type,
         e.event_type,e.liability_id,l.balance_model,l.payment_account_id,l.linked_account_id
  from public.cash_flow_event_funding f
  join public.transactions t on t.id=f.transaction_id
  join public.cash_flow_events e on e.id=f.cash_flow_event_id
  left join public.accounts fa on fa.id=t.from_account_id
  left join public.accounts ta on ta.id=t.to_account_id
  left join public.liabilities l on l.id=e.liability_id
  where t.occurred_at<=p_as_of
), buffer_commitments as (
  select e.account_id,
         sum(greatest(s.funded_amount-s.paid_amount,0)) as committed
  from st s join public.cash_flow_events e on e.id=s.event_id
  where e.account_id is not null
  group by e.account_id
)
select 'error','executed_without_full_payment','cash_flow_event',b.id,
       'Событие помечено исполненным без полного подтверждённого платежа',
       jsonb_build_object('amount',b.amount,'paid_amount',b.paid_amount,'status',b.status)
from base b
where b.event_type in ('expense','debt_payment','planned_expense')
  and p_as_of>=now() and b.status='executed' and b.paid_amount+0.005<b.amount
union all
select 'error','payment_link_points_to_buffer','allocation',a.allocation_id,
       'Связь payment указывает на перевод в платёжный буфер; это должно быть funding',
       jsonb_build_object('event_id',a.cash_flow_event_id,'transaction_id',a.transaction_id,'from_type',a.from_type,'to_type',a.to_type)
from allocation_semantics a
where a.relation_type='payment' and a.from_type in ('bank','cash') and a.to_type='payment_buffer'
union all
select 'error','funding_not_bank_to_buffer','allocation',a.allocation_id,
       'Связь funding не соответствует переводу bank/cash → payment_buffer',
       jsonb_build_object('event_id',a.cash_flow_event_id,'transaction_id',a.transaction_id,'transaction_type',a.transaction_type,'from_type',a.from_type,'to_type',a.to_type)
from allocation_semantics a
where a.relation_type='funding'
  and (a.transaction_type<>'transfer' or a.from_type not in ('bank','cash') or a.to_type<>'payment_buffer')
union all
select case when b.cash_still_required>0 then 'error' else 'warning' end,
       'overdue_unconfirmed','cash_flow_event',b.id,
       case when b.cash_still_required>0
            then 'Прошедшее обязательство не исполнено и требует денег/действия'
            else 'Прошедшее обязательство обеспечено, но списание не подтверждено' end,
       jsonb_build_object('event_date',b.event_date,'amount',b.amount,'remaining_payment_amount',b.remaining_payment_amount,'cash_still_required',b.cash_still_required,'derived_status',b.derived_status)
from base b
where b.event_type in ('expense','debt_payment','planned_expense')
  and b.event_date<public.finance_business_date(p_as_of)
  and b.derived_status not in ('executed','cancelled')
union all
select 'error','payment_buffer_shortfall','account',a.id,
       'Баланс платёжного буфера меньше суммы связанных обеспечений',
       jsonb_build_object('balance',public.get_account_balance(a.id,p_as_of),'committed',coalesce(c.committed,0))
from public.accounts a
join buffer_commitments c on c.account_id=a.id
where a.account_type='payment_buffer'
  and public.get_account_balance(a.id,p_as_of)+0.005<coalesce(c.committed,0)
union all
select 'warning','actual_date_without_payment','cash_flow_event',b.id,
       'У события есть actual_date, но нет подтверждённого payment',
       jsonb_build_object('actual_date',b.actual_date,'paid_amount',b.paid_amount,'status',b.status)
from base b
where b.event_type in ('expense','debt_payment','planned_expense')
  and b.actual_date is not null and b.paid_amount<=0
  and b.status<>'cancelled' and b.actual_date<=public.finance_business_date(p_as_of) and p_as_of>=now()
union all
select 'error',q.code,'data',q.entity_id,'Нарушена согласованность данных',q.details from public.finance_data_issues() q
union all
select 'warning','missing_liability_anchor','liability',l.id,'Неизвестен начальный остаток долга на выбранный момент',jsonb_build_object('as_of',p_as_of) from public.liabilities l where l.balance_model='installment' and not exists(select 1 from public.liability_balance_snapshots s where s.liability_id=l.id and s.balance_as_of<=p_as_of);
$function$;
