drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin" on public.profiles
for update to authenticated
using ((select auth.uid()) = id or (select private.is_admin()))
with check (
  (select private.is_admin())
  or (
    (select auth.uid()) = id
    and role = (select p.role from public.profiles p where p.id = (select auth.uid()))
  )
);

create or replace function public.protect_profile_role()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 if new.role is distinct from old.role and not private.is_admin() then
   raise exception 'Only the platform administrator can change account roles';
 end if;
 return new;
end;
$$;
drop trigger if exists protect_profile_role_trigger on public.profiles;
create trigger protect_profile_role_trigger
 before update on public.profiles for each row execute procedure public.protect_profile_role();

drop policy if exists "salons_owner_insert" on public.salons;
create policy "salons_owner_insert" on public.salons for insert to authenticated
with check (owner_id = (select auth.uid()) or (select private.is_admin()));

create or replace function public.set_profile_owner_role()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 update public.profiles set role='owner', updated_at=now()
 where id=new.owner_id and role='customer';
 return new;
end;
$$;
drop trigger if exists set_profile_owner_role_trigger on public.salons;
create trigger set_profile_owner_role_trigger
 after insert on public.salons for each row execute procedure public.set_profile_owner_role();

