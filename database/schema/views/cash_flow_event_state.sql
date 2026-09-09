CREATE VIEW public."cash_flow_event_state" WITH (security_invoker = true) AS
 SELECT event_id,
    event_date,
    event_type,
    amount,
    description,
    account_id,
    liability_id,
    status,
    paid_amount,
    funded_amount,
    cash_committed_amount,
    remaining_payment_amount,
    cash_still_required,
    derived_status
   FROM get_cash_flow_event_state_as_of(now()) get_cash_flow_event_state_as_of(event_id, event_date, event_type, amount, description, account_id, liability_id, status, paid_amount, funded_amount, cash_committed_amount, remaining_payment_amount, cash_still_required, derived_status);
