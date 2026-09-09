CREATE VIEW public."cash_flow_event_settlement_summary" WITH (security_invoker = true) AS
 SELECT e.id AS cash_flow_event_id,
    s.amount AS planned_amount,
    s.paid_amount,
    s.funded_amount,
    s.remaining_payment_amount,
    s.cash_still_required AS remaining_funding_amount
   FROM cash_flow_events e
     JOIN get_cash_flow_event_state_as_of(now()) s(event_id, event_date, event_type, amount, description, account_id, liability_id, status, paid_amount, funded_amount, cash_committed_amount, remaining_payment_amount, cash_still_required, derived_status) ON s.event_id = e.id;
