-- Seed idempotente das categorias em destaque da página inicial do MOZ SALÕES.
-- Executado directamente no projecto de produção em 2026-11-24.
-- A categoria Tranças já existia; as restantes são adicionadas sem apagar categorias antigas.
insert into public.categories (name, slug, description, active, sort_order)
values
  ('Manicure', 'manicure', 'Cuidados e tratamentos das unhas das mãos.', true, 10),
  ('Pedicure', 'pedicure', 'Cuidados e tratamentos das unhas dos pés.', true, 11),
  ('Lavagem', 'lavagem', 'Lavagem e preparação dos cabelos.', true, 12),
  ('Corte', 'corte', 'Cortes e modelagem de cabelo.', true, 13),
  ('Retoque', 'retoque', 'Retoques e manutenção de penteados e cabelos.', true, 14)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    active = true,
    sort_order = excluded.sort_order;

update public.categories
set active = true
where slug = 'trancas';
