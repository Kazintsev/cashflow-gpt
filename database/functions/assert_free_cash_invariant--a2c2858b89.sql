CREATE OR REPLACE FUNCTION public.assert_free_cash_invariant(p_before numeric, p_after numeric, p_context text, p_tolerance numeric DEFAULT 0.01)
 RETURNS void
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if p_before is not null and p_after is not null and abs(p_before-p_after)>p_tolerance then
    raise exception 'free_cash_until_next_income invariant failed for %: before %, after %, delta %',p_context,p_before,p_after,p_after-p_before;
  end if;
end
$function$;
