-- Mantém os preços oficiais de publicação definidos para o MOZ SALÕES.
-- As isenções gratuitas usam estes valores apenas para registar o montante dispensado.
update public.subscription_plans
set price_mzn = case duration_days
  when 30 then 20
  when 60 then 40
  when 90 then 60
  else price_mzn
end
where duration_days in (30, 60, 90);

