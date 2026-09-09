CREATE OR REPLACE FUNCTION public.finance_setting_text(p_key text, p_default text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$ SELECT COALESCE((SELECT value #>> '{}' FROM public.finance_settings WHERE key=p_key),p_default) $function$;
