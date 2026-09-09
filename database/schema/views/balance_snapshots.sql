CREATE VIEW public."balance_snapshots" WITH (security_invoker = true) AS
 SELECT id,
    account_id,
    balance_date,
    balance,
    notes,
    created_at,
    balance_as_of
   FROM account_balance_snapshots;
