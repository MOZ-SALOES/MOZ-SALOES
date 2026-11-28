-- Allow the system's salon-insert trigger to promote a customer to owner.
-- All other role changes remain restricted to the platform administrator.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.role is distinct from old.role
     and not private.is_admin()
     and not (
       old.role = 'customer'
       and new.role = 'owner'
       and exists (
         select 1 from public.salons s where s.owner_id = old.id
       )
     ) then
    raise exception 'Only the platform administrator can change account roles, except customer-to-owner after salon registration';
  end if;
  return new;
end;
$function$;
