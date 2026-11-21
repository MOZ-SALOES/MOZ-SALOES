-- Imagem pública identificada para The Mani Pedi Spa Maputo.
-- Os restantes estabelecimentos recebem ilustrações geradas na interface até haver fotos próprias confirmadas.
insert into public.salon_images (salon_id, image_path, caption, sort_order)
select s.id,
       'https://images.fresha.com/locations/location-profile-images/50598/2116536/08fc7131-2346-4f08-bb63-a16f2bffa904-TheManiPediSpaMaputo-MZ-Maputo-Maputo-Sommerschield-Fresha.jpg?class=venue-gallery-mobile&f_width=3840',
       'Fotografia pública do espaço — fonte: Fresha',
       0
from public.salons s
where s.slug = 'the-mani-pedi-spa-maputo'
  and not exists (
    select 1 from public.salon_images si
    where si.salon_id = s.id
      and si.caption = 'Fotografia pública do espaço — fonte: Fresha'
  );
