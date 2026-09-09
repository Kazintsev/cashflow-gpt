CREATE OR REPLACE FUNCTION public.get_expense_category_lines(p_start date, p_end date)
 RETURNS TABLE(transaction_id bigint, transaction_date date, description text, category_id bigint, category_name text, amount numeric, allocation_source text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with tx as (
    select t.* from public.transactions t
    where t.transaction_type='expense' and t.transaction_date between p_start and p_end
  ), alloc as (
    select a.transaction_id,a.category_id,a.amount,a.allocation_source
    from public.transaction_category_allocations a join tx on tx.id=a.transaction_id
  )
  select t.id,t.transaction_date,t.description,a.category_id,c.name,a.amount,a.allocation_source
  from tx t join alloc a on a.transaction_id=t.id join public.categories c on c.id=a.category_id
  union all
  select t.id,t.transaction_date,t.description,t.category_id,c.name,t.amount,'transaction'::text
  from tx t left join public.categories c on c.id=t.category_id
  where not exists(select 1 from alloc a where a.transaction_id=t.id)
  order by 2,1,5;
$function$;
