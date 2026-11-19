create or replace function private.can_manage_salon_image_path(
  p_owner_folder text,
  p_salon_folder text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.salons s
    where s.id::text = p_salon_folder
      and (
        (
          s.owner_id = (select auth.uid())
          and p_owner_folder = (select auth.uid())::text
        )
        or (select private.is_admin())
      )
  );
$$;

revoke all on function private.can_manage_salon_image_path(text, text) from public, anon;
grant execute on function private.can_manage_salon_image_path(text, text) to authenticated;

drop policy if exists salon_images_bucket_public_read on storage.objects;
drop policy if exists salon_images_owner_delete on storage.objects;
drop policy if exists salon_images_owner_update on storage.objects;
drop policy if exists salon_images_owner_upload on storage.objects;

create policy salon_images_owner_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'salon-images'
  and private.can_manage_salon_image_path(
    (storage.foldername(name))[1],
    (storage.foldername(name))[2]
  )
);

create policy salon_images_owner_upload
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'salon-images'
  and private.can_manage_salon_image_path(
    (storage.foldername(name))[1],
    (storage.foldername(name))[2]
  )
);

create policy salon_images_owner_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'salon-images'
  and private.can_manage_salon_image_path(
    (storage.foldername(name))[1],
    (storage.foldername(name))[2]
  )
)
with check (
  bucket_id = 'salon-images'
  and private.can_manage_salon_image_path(
    (storage.foldername(name))[1],
    (storage.foldername(name))[2]
  )
);

create policy salon_images_owner_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'salon-images'
  and private.can_manage_salon_image_path(
    (storage.foldername(name))[1],
    (storage.foldername(name))[2]
  )
);

revoke all on table storage.objects from anon;
grant select, insert, update, delete on table storage.objects to authenticated;

