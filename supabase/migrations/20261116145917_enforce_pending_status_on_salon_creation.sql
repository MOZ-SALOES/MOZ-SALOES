create or replace function public.guard_salon_admin_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if not private.is_admin() then
    if tg_op = 'INSERT' then
      new.status := 'pending';
      new.verified := false;
      new.publication_expires_at := null;
    else
      if new.owner_id is distinct from old.owner_id
         or new.status is distinct from old.status
         or new.verified is distinct from old.verified
         or new.publication_expires_at is distinct from old.publication_expires_at then
        raise exception 'Only the platform administrator can change salon ownership, approval or publication validity';
      end if;
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists guard_salon_admin_fields_trigger on public.salons;
create trigger guard_salon_admin_fields_trigger
before insert or update on public.salons
for each row execute function public.guard_salon_admin_fields();
