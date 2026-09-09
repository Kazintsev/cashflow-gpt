CREATE VIEW public."liability_current_balances" WITH (security_invoker = true) AS
 SELECT l.id AS liability_id,
    l.name,
    l.liability_type,
    l.balance_model,
    b.principal_balance,
    b.accrued_interest,
    b.fees_due,
    b.total_debt,
    l.payment_account_id,
    l.linked_account_id
   FROM liabilities l
     LEFT JOIN LATERAL get_liability_balance(l.id, now()) b(principal_balance, accrued_interest, fees_due, total_debt) ON true;
