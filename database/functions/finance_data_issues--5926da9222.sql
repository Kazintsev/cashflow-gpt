CREATE OR REPLACE FUNCTION public.finance_data_issues()
 RETURNS TABLE(code text, entity_id bigint, details jsonb)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
 SELECT 'transaction_date_mismatch',t.id,to_jsonb(t) FROM public.transactions t WHERE t.transaction_date<>public.finance_business_date(t.occurred_at)
 UNION ALL
 SELECT 'category_allocation_mismatch',t.id,jsonb_build_object('amount',t.amount,'allocated',a.total)
 FROM public.transactions t JOIN (SELECT transaction_id,sum(amount) total FROM public.transaction_category_allocations GROUP BY transaction_id)a ON a.transaction_id=t.id
 WHERE t.transaction_type<>'expense' OR round(t.amount,2)<>round(a.total,2)
 UNION ALL
 SELECT 'debt_detail_mismatch',t.id,jsonb_build_object('amount',t.amount,'detail_id',d.id)
 FROM public.transactions t JOIN public.debt_payment_details d ON d.transaction_id=t.id
 WHERE t.transaction_type<>'debt_payment' OR t.liability_id IS DISTINCT FROM d.liability_id OR round(t.amount,2)<>round(d.principal_amount+d.interest_amount+d.fee_amount,2)
 UNION ALL
 SELECT 'allocation_exceeds_transaction',t.id,jsonb_build_object('amount',t.amount,'allocated',a.total)
 FROM public.transactions t JOIN (SELECT transaction_id,sum(amount) total FROM public.cash_flow_event_funding GROUP BY transaction_id)a ON a.transaction_id=t.id WHERE a.total>t.amount+0.005
 UNION ALL
 SELECT 'allocation_exceeds_event',e.id,jsonb_build_object('amount',e.amount,'allocated',a.total,'relation',a.relation_type)
 FROM public.cash_flow_events e JOIN (SELECT cash_flow_event_id,relation_type,sum(amount) total FROM public.cash_flow_event_funding GROUP BY cash_flow_event_id,relation_type)a ON a.cash_flow_event_id=e.id WHERE a.total>e.amount+0.005
 UNION ALL
 SELECT 'cash_commitment_exceeds_event',e.id,jsonb_build_object('amount',e.amount,'allocated',a.total)
 FROM public.cash_flow_events e JOIN (SELECT f.cash_flow_event_id,sum(f.amount) total FROM public.cash_flow_event_funding f JOIN public.transactions t ON t.id=f.transaction_id JOIN public.accounts a ON a.id=t.from_account_id WHERE a.account_type IN ('bank','cash') GROUP BY f.cash_flow_event_id)a ON a.cash_flow_event_id=e.id WHERE a.total>e.amount+0.005
 UNION ALL
 SELECT 'allocation_semantics',f.id,jsonb_build_object('event',e.id,'transaction',t.id,'relation',f.relation_type)
 FROM public.cash_flow_event_funding f JOIN public.transactions t ON t.id=f.transaction_id JOIN public.cash_flow_events e ON e.id=f.cash_flow_event_id
 LEFT JOIN public.accounts fa ON fa.id=t.from_account_id LEFT JOIN public.accounts ta ON ta.id=t.to_account_id LEFT JOIN public.liabilities l ON l.id=e.liability_id
 WHERE (CASE WHEN f.relation_type='funding' THEN
   t.transaction_type='transfer' AND fa.account_type IN ('bank','cash') AND ta.account_type='payment_buffer' AND e.event_type IN ('expense','debt_payment','planned_expense')
   AND (e.liability_id IS NULL OR (l.balance_model='installment' AND t.to_account_id=l.payment_account_id))
   AND (e.liability_id IS NOT NULL OR e.account_id IS NULL OR t.to_account_id=e.account_id)
 ELSE
   CASE WHEN e.event_type='debt_payment' THEN t.transaction_type='debt_payment' AND t.liability_id=e.liability_id AND
    ((l.balance_model='installment' AND t.from_account_id=l.payment_account_id AND t.to_account_id IS NULL) OR (l.balance_model='revolving_account' AND fa.account_type IN ('bank','cash') AND t.to_account_id=l.linked_account_id))
   WHEN e.event_type IN ('expense','planned_expense') THEN t.transaction_type='expense' AND fa.account_type IN ('bank','cash','payment_buffer') AND t.to_account_id IS NULL AND (NOT e.living_budget_exempt OR t.budget_effect<>'life')
   ELSE false END END) IS NOT TRUE
 UNION ALL
 SELECT 'receipt_amount_mismatch',r.id,jsonb_build_object('receipt',r.total_amount,'transaction',t.amount) FROM public.receipts r JOIN public.transactions t ON t.id=r.transaction_id WHERE t.transaction_type<>'expense' OR round(r.total_amount,2)<>round(t.amount,2)
 UNION ALL
 SELECT 'receipt_items_mismatch',r.id,jsonb_build_object('receipt',r.total_amount,'items',coalesce(a.total,0)) FROM public.receipts r LEFT JOIN (SELECT receipt_id,sum(amount) total FROM public.receipt_items GROUP BY receipt_id)a ON a.receipt_id=r.id
 WHERE r.parse_status IN ('items_parsed','verified_online') AND round(r.total_amount,2)<>round(coalesce(a.total,0),2)
 UNION ALL
 SELECT 'income_link_mismatch',t.id,jsonb_build_object('event',t.income_event_id) FROM public.transactions t JOIN public.cash_flow_events e ON e.id=t.income_event_id WHERE t.transaction_type<>'income' OR e.event_type<>'income'
 UNION ALL
 SELECT 'liability_account_mismatch',l.id,jsonb_build_object('model',l.balance_model,'payment_account',l.payment_account_id,'linked_account',l.linked_account_id)
 FROM public.liabilities l LEFT JOIN public.accounts p ON p.id=l.payment_account_id LEFT JOIN public.accounts a ON a.id=l.linked_account_id
 WHERE (CASE WHEN l.balance_model='installment' THEN p.account_type='payment_buffer' ELSE a.account_type='credit_card' END) IS NOT TRUE
 UNION ALL
 SELECT 'detail_event_mismatch',d.id,jsonb_build_object('event',e.id,'liability',d.liability_id) FROM public.debt_payment_details d JOIN public.cash_flow_events e ON e.id=d.cash_flow_event_id WHERE e.event_type<>'debt_payment' OR e.liability_id IS DISTINCT FROM d.liability_id
 UNION ALL
 SELECT 'schedule_event_mismatch',e.id,jsonb_build_object('schedule',s.id) FROM public.cash_flow_events e JOIN public.liability_payment_schedule s ON s.id=e.liability_payment_schedule_id WHERE e.liability_id IS DISTINCT FROM s.liability_id OR e.event_type<>'debt_payment'
 UNION ALL
 SELECT 'movement_time_mismatch',m.id,jsonb_build_object('transaction',t.id) FROM public.liability_movements m JOIN public.transactions t ON t.id=m.transaction_id WHERE m.debt_payment_detail_id IS NOT NULL AND m.effective_at<>t.occurred_at;
$function$;
