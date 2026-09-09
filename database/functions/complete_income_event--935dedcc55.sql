CREATE OR REPLACE FUNCTION public.complete_income_event(p_event_id bigint, p_completed_at timestamp with time zone DEFAULT now())
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
 PERFORM pg_advisory_xact_lock(20260905,731);
 IF NOT EXISTS(SELECT 1 FROM public.cash_flow_events WHERE id=p_event_id AND event_type='income' AND status<>'cancelled') THEN RAISE EXCEPTION 'active income event % not found',p_event_id;END IF;
 IF NOT EXISTS(SELECT 1 FROM public.transactions WHERE income_event_id=p_event_id AND occurred_at<=p_completed_at) THEN RAISE EXCEPTION 'income completion requires a receipt';END IF;
 UPDATE public.cash_flow_events SET income_completed_at=p_completed_at WHERE id=p_event_id;
 PERFORM public.refresh_cash_flow_event_status(p_event_id);
END $function$;
