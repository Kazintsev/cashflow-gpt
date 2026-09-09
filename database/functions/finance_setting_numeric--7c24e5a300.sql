CREATE OR REPLACE FUNCTION public.finance_setting_numeric(p_key text, p_default numeric DEFAULT NULL::numeric)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT COALESCE((SELECT (value #>> '{}')::numeric FROM public.finance_settings WHERE key=p_key),p_default) $function$;
