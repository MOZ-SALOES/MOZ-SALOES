create or replace function public.guard_salon_admin_fields()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 if not private.is_admin() then
   if new.owner_id is distinct from old.owner_id
      or new.status is distinct from old.status
      or new.verified is distinct from old.verified
      or new.publication_expires_at is distinct from old.publication_expires_at then
     raise exception 'Only the platform administrator can change salon ownership, approval or publication validity';
   end if;
 end if;
 return new;
end;
$$;
revoke all on function public.guard_salon_admin_fields() from public, anon, authenticated;
drop trigger if exists guard_salon_admin_fields_trigger on public.salons;
create trigger guard_salon_admin_fields_trigger
 before update on public.salons for each row execute procedure public.guard_salon_admin_fields();

