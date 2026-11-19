insert into public.admin_settings(key, value, updated_at)
values
  ('admin_email', to_jsonb('miltonjustino888@gmail.com'::text), now()),
  ('admin_name', to_jsonb('Silda'::text), now())
on conflict (key) do update
set value = excluded.value, updated_at = now();

create or replace function private.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  authorized_email text;
  administrator_name text;
  assigned_role text;
  profile_name text;
begin
  select s.value #>> '{}'
    into authorized_email
  from public.admin_settings s
  where s.key = 'admin_email';

  select s.value #>> '{}'
    into administrator_name
  from public.admin_settings s
  where s.key = 'admin_name';

  if lower(coalesce(new.email, '')) = lower(coalesce(authorized_email, '')) then
    assigned_role := 'admin';
    profile_name := coalesce(nullif(administrator_name, ''), 'Silda');
  else
    assigned_role := 'customer';
    profile_name := coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      split_part(coalesce(new.email, ''), '@', 1)
    );
  end if;

  insert into public.profiles (id, full_name, email, phone, role)
  values (
    new.id,
    profile_name,
    new.email,
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    assigned_role
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email,
        phone = coalesce(excluded.phone, public.profiles.phone),
        role = case
          when excluded.role = 'admin' then 'admin'
          else public.profiles.role
        end,
        updated_at = now();

  return new;
end;
$function$;

drop trigger if exists on_auth_user_created_profile on auth.users;

create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function private.handle_new_user_profile();

revoke all on function private.handle_new_user_profile() from public, anon, authenticated;

