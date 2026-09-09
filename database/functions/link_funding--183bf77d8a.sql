CREATE OR REPLACE FUNCTION public.link_funding(p_event_id bigint, p_transaction_id bigint, p_amount numeric)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT public.link_funding(p_event_id,p_transaction_id,p_amount,'funding') $function$;
