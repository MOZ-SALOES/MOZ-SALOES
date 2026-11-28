-- This helper is invoked only by the salon-insert trigger.
create or replace function private.mark_profile_as_owner_after_salon_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  update public.profiles
     set role='owner', updated_at=now()
   where id=new.owner_id and role='customer';
  return new;
end;
$function$;
revoke all on function private.mark_profile_as_owner_after_salon_insert() from public, anon, authenticated;
drop trigger if exists salons_mark_owner_profile on public.salons;
create trigger salons_mark_owner_profile after insert on public.salons
  for each row execute function private.mark_profile_as_owner_after_salon_insert();
