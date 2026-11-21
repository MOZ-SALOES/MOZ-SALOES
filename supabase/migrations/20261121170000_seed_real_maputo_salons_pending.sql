-- Seed de estabelecimentos reais de Maputo para validação administrativa.
-- Todos entram como pendentes, sem subscrição, pagamento ou selo de verificação.
-- As páginas são registos informativos baseados em fontes públicas; não implicam parceria.
do $$
declare
  admin_owner uuid;
  inserted_count integer;
begin
  select p.id
    into admin_owner
  from public.profiles p
  where lower(p.email) = 'miltonjustino888@gmail.com'
    and p.role = 'admin'
  order by p.created_at
  limit 1;

  if admin_owner is null then
    raise exception 'Não foi encontrado o perfil administrador miltonjustino888@gmail.com. Cria/entra primeiro na conta de administrador e volta a executar esta migração.';
  end if;

  with candidates(name, slug, category_slug, phone, address) as (
    values
      ('Marisa Vaz - Beauty Clinic / Academy', 'marisa-vaz-beauty-clinic-maputo', 'tratamentos', '+258 84 924 2424', 'Avenida Patrice Lumumba, n.º 290, Maputo'),
      ('The Mani Pedi Spa Maputo', 'the-mani-pedi-spa-maputo', 'unhas', '+258 84 217 2463', 'Rua dos Cronistas, n.º 121, Sommerschield, Maputo'),
      ('Gentleman''s Barber Shop - Av. Eduardo Mondlane', 'gentlemans-barber-shop-248-maputo', 'barbearia', '+258 84 550 9796', 'Avenida Eduardo Mondlane, n.º 248, Maputo'),
      ('Sonal Beauty Parlor', 'sonal-beauty-parlor-maputo', 'beleza-geral', '+258 84 747 1154', 'Avenida Ho Chi Min, Maputo'),
      ('ManCave', 'mancave-maputo', 'barbearia', '+258 84 400 1349', 'Avenida Olof Palme, n.º 12, Maputo'),
      ('Tchetcho''s Barber Shop', 'tchetchos-barber-shop-maputo', 'barbearia', '+258 84 300 9299', 'Rua de Silves, Malhangalene, Maputo'),
      ('Clays Barber Shop', 'clays-barber-shop-maputo', 'barbearia', '+258 84 413 2046', 'Avenida Maguiguana, esquina com Avenida Albert Luthuli, Maputo'),
      ('Beto''s Look', 'betos-look-maputo', 'beleza-geral', '+258 84 848 0319', 'Shopping 24, Loja 19, Avenida 24 de Julho, Maputo'),
      ('Ctrl+X', 'ctrl-x-barber-shop-maputo', 'barbearia', '+258 84 792 2314', 'Avenida Salvador Allende, Maputo'),
      ('Barbearia ZIZOU', 'barbearia-zizou-maputo', 'barbearia', '+258 86 208 7000', 'Avenida Josina Machel, n.º 1410, Maputo'),
      ('Afriki Beauty Center', 'afriki-beauty-center-maputo', 'cabelo', '+258 84 015 7388', 'Avenida Karl Marx, n.º 1975, R/C, Maputo'),
      ('Purple Haze Salon & Beauty Clinic', 'purple-haze-salon-beauty-clinic-maputo', 'beleza-geral', '+258 84 246 1348', 'Avenida Vladimir Lenine, Maputo'),
      ('Belle De Jour', 'belle-de-jour-maputo', 'cabelo', '+258 84 773 7776', 'Avenida Vladimir Lenine, Malhangalene B, Maputo'),
      ('BodyCare Clinica de Estética', 'bodycare-clinica-estetica-maputo', 'tratamentos', null, 'Avenida Paulo Samuel Kankhomba, n.º 417, Maputo'),
      ('Lotus Spa', 'lotus-spa-maputo', 'tratamentos', '+258 87 219 7994', 'Avenida/ Rua da Frente de Libertação de Moçambique, n.º 206, Maputo')
  ),
  inserted as (
    insert into public.salons (
      owner_id, name, slug, description, category_id, phone,
      province, district, city, address, status, verified,
      publication_expires_at
    )
    select
      admin_owner,
      c.name,
      c.slug,
      'Registo informativo de um estabelecimento identificado em fontes públicas. Aguardando validação pelo proprietário. A inclusão no MOZ SALÕES não significa parceria nem autorização de gestão da página.',
      cat.id,
      c.phone,
      'Maputo Cidade',
      'KaMpfumo',
      'Maputo',
      c.address,
      'pending',
      false,
      null
    from candidates c
    left join public.categories cat on cat.slug = c.category_slug
    where not exists (
      select 1 from public.salons existing where existing.slug = c.slug
    )
    returning id
  )
  select count(*) into inserted_count from inserted;

  insert into public.audit_logs(actor_id, action, entity_type, details)
  values (
    admin_owner,
    'maputo_public_salons_imported_pending',
    'salons',
    jsonb_build_object(
      'inserted_count', inserted_count,
      'free_listing', true,
      'status', 'pending',
      'source_note', 'Public business directories and listings; owner validation required',
      'no_payment_created', true
    )
  );

  raise notice 'Foram adicionados % registos pendentes de salões de Maputo.', inserted_count;
end $$;
