CREATE OR REPLACE FUNCTION public.clear_credit_card_minimum_allocations()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$ BEGIN DELETE FROM public.cash_flow_event_funding WHERE transaction_id=OLD.id AND allocation_source='auto_card_minimum'; IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END $function$;
