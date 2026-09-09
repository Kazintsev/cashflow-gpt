CREATE OR REPLACE FUNCTION public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric, p_relation_type text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$ BEGIN IF p_amount<=0 THEN RAISE EXCEPTION 'p_amount must be > 0';END IF;IF p_relation_type NOT IN ('funding','payment') THEN RAISE EXCEPTION 'invalid relation_type';END IF;INSERT INTO public.cash_flow_event_funding(cash_flow_event_id,transaction_id,amount,relation_type) VALUES(p_event_id,p_transaction_id,p_amount,p_relation_type);PERFORM public.refresh_cash_flow_event_status(p_event_id);END $function$;
